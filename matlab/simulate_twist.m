function simulate_twist(parts, varargin)
    % Simulation parameter parsing
    p = inputParser;
    addParameter(p, 'dt', 0.01);                % timestep
    addParameter(p, 'lambda', 0.5 * 1700);    	% Lame parameter 1
    addParameter(p, 'mu', 0.5 * 15000);        	% Lame parameter 2
    addParameter(p, 'gravity', -300);          	% gravity force (direction is -z direction)
    addParameter(p, 'k_stability', 1e5);       	% stiffness for stability term
    addParameter(p, 'order', 1);              	% (1 or 2) linear or quadratic deformation
    addParameter(p, 'rho', 1);                 	% per point density (currently constant)
    addParameter(p, 'save_output', 0);        	% (0 or 1) whether to output images of simulation
    addParameter(p, 'save_obj', 0);          	% (0 or 1) whether to output obj files
    addParameter(p, 'save_iges', 0);          	% (0 or 1) whether to output iges files
    addParameter(p, 'save_resultion', 20);    	% the amount of subdivision for the output obj
    addParameter(p, 'pin_function', @(x) 1);
    addParameter(p, 'sample_interior', 1);
    addParameter(p, 'distance_cutoff', 20);
    addParameter(p, 'enable_secondary_rays', true);
    addParameter(p, 'fitting_mode', 'hierarchical');
    addParameter(p, 'plot_points', false);
    addParameter(p, 'plot_com', true);
    addParameter(p, 'initial_velocity', [0 0 0]);
    addParameter(p, 'x_samples', 5);
    addParameter(p, 'y_samples', 9);
    addParameter(p, 'z_samples', 9);
    addParameter(p, 'f_external', [0 0 0]);
    addParameter(p, 'f_external_time', 1000);
    addParameter(p, 'save_obj_path', 'output/obj/');

    parse(p,varargin{:});
    config = p.Results;
    
    d = 3;              % dimension (2 or 3)
    n = numel(parts);	% number of shapes
    
    % The number of elements in the monomial basis.
    k = basis_size(d, config.order);
    
    % Read in NURBs 
    fig=figure(1);
    clf;
%     [plt,plt_AO]=nurbs_pretty_plot(parts);
    parts=nurbs_plot(parts);

    % Assembles global generalized coordinates
    [J, ~, q, E, x0, S] = nurbs_assemble_coords(parts);
    
    % Initial deformed positions and velocities
    x = x0;
    qdot = reshape(repmat(config.initial_velocity, size(q,1)/3, 1)', [], 1);
    
%     pin_I = config.pin_function(x0);
  	x_beg = 0;
    pin_I = [];
    rot_I = [];
    for i = 1: numel(parts)
        if parts{i}.srf.color(1) == 1
            i
        	x_end = x_beg + size(parts{i}.x0,2);
            x_beg = x_beg + 1;
            pin_I = [pin_I x_beg:3:x_end];
            %break;
            if isempty(rot_I)
                rot_I = pin_I;
            end
        end
        x_beg = x_beg + size(parts{i}.x0,2) - 1;
    end
    
    rot_c = mean(x(:,rot_I),2);
    P = fixed_point_constraint_matrix(x0',sort(pin_I)');
    
    % Plotting pinned vertices.
%     X_plot=plot3(x(1,pin_I),x(2,pin_I),x(3,pin_I),'.','Color','red','MarkerSize',20);
    hold on;
    
    % Sampling points used to compute energies.
    if config.sample_interior
        yz_samples = [config.y_samples config.z_samples];
        [V, vol] = raycast_quadrature(parts, yz_samples, config.x_samples);
    else
    	V=x0;
        vol=ones(size(V,2),1);
    end
    m = size(V,2);  % number of quadrature points
    
    if config.plot_points
        V_plot=plot3(V(1,:),V(2,:),V(3,:),'.','Color','m','MarkerSize',20);
    end
    
    % Lame parameters concatenated.
    params = [config.mu * 0.5, config.lambda * 0.5];
    params = repmat(params,size(V,2),1);
        
    % Compute Shape weights
    [w, w_I] = nurbs_blending_weights(parts, V', config.distance_cutoff, ...
        'Enable_Secondary_Rays', config.enable_secondary_rays);
    [w0, w0_I] = nurbs_blending_weights(parts, x0', config.distance_cutoff, ...
        'Enable_Secondary_Rays', config.enable_secondary_rays);
    
    % Generate centers of mass.
    [x0_coms, com_cluster, com_map] = generate_com(x0, E, w, n, parts);
    if config.plot_com
        com_plt = plot3(x0_coms(1,:),x0_coms(2,:),x0_coms(3,:), ...
                        '.','Color','g','MarkerSize',20);
        hold on;
    end
    
    % Shape Matrices
    L = compute_shape_matrices(x0, x0_coms, com_map, E, ...
        com_cluster, config.order, config.fitting_mode, S);

    % Build Monomial bases for all quadrature points
    [Y,Y_S,C_I] = vem_dx_dc(V, x0_coms, w, w_I, com_map, config.order, k);
    [Y0,Y0_S,C0_I] = vem_dx_dc(x0, x0_coms, w0, w0_I, com_map, config.order, k);

    % Fixed x values.
    x_fixed = zeros(size(x0));
    for i = 1:numel(pin_I)
        x_fixed(:,pin_I(i))=x0(:,pin_I(i));
    end
    
    % Applying fixed point constraints to NURBS jacobian.
    J = P * J;    
    
    % Computing each gradient of deformation gradient with respect to
    % projection operator (c are polynomial coefficients)
    [dF_dc, dF_dc_S] = vem_dF_dc(V, x0_coms, w, w_I, com_map, config.order, k);

    % Gravity force vector.
    dg_dc = vem_ext_force([0 0 config.gravity]', config.rho*vol, Y, Y_S);
    f_gravity = config.dt*P*(L' * dg_dc);
    
    % Optional external force vector
    dext_dc = vem_ext_force(config.f_external', config.rho*vol, Y, Y_S);
    f_external = config.dt*P*(L' * dext_dc); 

    % Compute mass matrices
%     ME = vem_error_matrix(Y0, L, w0_I, C0_I, d, k, n);
%     M = vem_mass_matrix(Y, L, config.rho .* vol, w_I, C_I, d, k, n);
    % make sure matlab/deprecated is on your path to use these versions
    M = vem_mass_matrix_matlab(Y, Y_S, L, config.rho .* vol);
    ME = vem_error_matrix_matlab(Y0, Y0_S, L, d);
    M = (M + config.k_stability*ME);

    ii=1;
    img_ii=1;
    obj_ii=1;
    for t=0:config.dt:30
        tic

        % Preparing input for stiffness matrix mex function.
        b = [];
        for i=1:numel(E)
            b = [b (x(:,E{i}))];
        end
        b = b(:);

        % Solve for polynomial coefficients (projection operators).
        c = L * b;

        % Stiffness matrix (mex function)
        K = -vem3dmesh_neohookean_dq2(c, vol, params, dF_dc, w_I, k, n, ...
                                      size(x0_coms,2));
        K = L' * K * L;

        % Force vector
        dV_dq = zeros(d*(k*n + size(x0_coms,2)),1);
        
        % Computing force dV/dq for each point.
        % TODO: move this to C++ :)
        for i = 1:m
            % Deformation Gradient
            F = dF_dc{i} * dF_dc_S{i} * c;
            F = reshape(F,d,d);
            
            V(:,i) = Y{i} * Y_S{i} * c;
            
            % Force vector
            dV_dF = neohookean_tet_dF(F, params(i,1), params(i,2));
            dV_dq = dV_dq +  dF_dc_S{i}' * dF_dc{i}' * dV_dF * vol(i);
        end        
        dV_dq = L' * dV_dq;
        
        % Error correction force
        f_error = - 2 * ME * x(:);
        f_error = config.k_stability*(config.dt * P * f_error(:));
       
        % Force from potential energy.
        f_internal = -config.dt*P*dV_dq;
        
        % Computing linearly-implicit velocity update
        % Note: I believe i'm forgetting the error matrix stiffness matrix
        %       but I don't wanna break things so I haven't added it yet.
        lhs = J' * (P*(M - config.dt*config.dt*K)*P') * J;
        rhs = J' * (P*M*P'*J*qdot + f_internal + f_gravity + f_error + f_external);
        qdot = lhs \ rhs;

        % Update position
        q = q + config.dt*qdot;
        x_fixed_rot = x_fixed;
        rot_t=0.25;
        x_fixed_rot(2,rot_I) = 0.5+(x_fixed(2,rot_I)-rot_c(2))*cosd(rot_t*ii) -  (x_fixed(3,rot_I)-rot_c(2))*sind(rot_t*ii);
        x_fixed_rot(3,rot_I) = 0.5+(x_fixed(2,rot_I)-rot_c(3))*sind(rot_t*ii) +  (x_fixed(3,rot_I)-rot_c(3))*cosd(rot_t*ii);
        x = reshape(P'*J*q,3,[]) + x_fixed_rot;
%         X_plot.YData=x_fixed_rot(2,pin_I);
%         X_plot.ZData=x_fixed_rot(3,pin_I);
        rot_t*ii
        % Update NURBs plots
        x_idx=0;
        
%         plt.Vertices=x';
%         plt_AO=apply_ambient_occlusion(plt,'AddLights',false,'AO',plt_AO);

        for i=1:numel(parts)
            x_sz = size(parts{i}.x0,2);
            xi = x(:,x_idx+1:x_idx+x_sz);
            parts{i}.plt.Vertices =xi';
            x_idx = x_idx+x_sz;
        end
%         
%         if config.plot_com
%             x_coms = c(d*k*n + 1:end); % extract centers of mass
%             com_plt.XData = x_coms(1:d:end);
%             com_plt.YData = x_coms(2:d:end);
%             com_plt.ZData = x_coms(3:d:end);
%         end
%         
%         if config.plot_points
%             V_plot.XData = V(1,:);
%             V_plot.YData = V(2,:);
%             V_plot.ZData = V(3,:);
%         end
        drawnow
        
        if config.save_obj && mod(ii,4)==0
            obj_fn = config.save_obj_path + "part_" + int2str(obj_ii) + ".obj";
            nurbs_write_obj(q,parts,obj_fn,obj_ii);
            obj_ii = obj_ii + 1;
        end
        
        if config.save_iges
            obj_fn = config.save_obj_path + "part_" + int2str(ii) + ".iges";
            nurbs_write_iges(q,parts,obj_fn);
        end

        if config.save_output && mod(ii,4)==0
            fn=sprintf('output/img/simulate_beem_%03d.png',img_ii);
            saveas(fig,fn);
            img_ii = img_ii + 1;
        end
        ii=ii+1
        toc
    end
end

