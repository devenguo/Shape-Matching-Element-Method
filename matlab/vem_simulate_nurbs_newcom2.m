function vem_simulate_nurbs_newcom2(parts, varargin)
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
    addParameter(p, 'save_resultion', 20);    	% the amount of subdivision for the output obj
    addParameter(p, 'pin_function', @(x) 1);
    addParameter(p, 'sample_interior', 1);
    addParameter(p, 'distance_cutoff', 20);
    addParameter(p, 'enable_secondary_rays', true);
    addParameter(p, 'fitting_mode', 'global');
    parse(p,varargin{:});
    config = p.Results;
    
    d = 3;              % dimension (2 or 3)
    n = numel(parts);	% number of shapes
    
    % The number of elements in the monomial basis.
    k = basis_size(d, config.order);
    
    % Read in NURBs 
    fig=figure(1);
    clf;
    parts=nurbs_plot(parts);

    % Assembles global generalized coordinates
    [J, ~, q, E, x0] = nurbs_assemble_coords(parts);

    %%%%%%%%%%%%%%%%%%%%%%%%
    % Creating centers of mass
    %%
    centroids = zeros(n, 3);
    x0_coms = zeros(3,n);
    for i=1:n
        centroids(i,:) = mean(parts{i}.x0,2)';
    end
    
    cutoff_sqr = (2*config.distance_cutoff)^2;
    adj = zeros(n,n);
    for i=1:n
    	F = parts{i}.hires_T;
        V = parts{i}.hires_x0';
        sqrD = point_mesh_squared_distance(centroids,V,F);
        adj(:,i) = sqrD < cutoff_sqr;
    end
    
    adjacent = cell(n,1);
    for i=1:n
       	adj_idx = find(adj(i,:));
        x_idx=cell2mat(E(adj_idx));
        adjacent{i} = x_idx(:);
        x0_coms(:,i) = mean(x0(:,adjacent{i}),2);
    end
    %%
    
    %%%% Test single com %%%%
    com_map = ones(n,1);
    x0_coms = mean(x0,2);
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    com_plt = plot3(x0_coms(1,:),x0_coms(2,:),x0_coms(3,:), ...
                    '.','Color','g','MarkerSize',20);
    hold on;
    x_coms=x0_coms;
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    % Initial deformed positions and velocities
    x = x0;
    qdot=zeros(size(q));
    
    % Setup pinned vertices constraint matrix
    pin_I = config.pin_function(x0);
    P = fixed_point_constraint_matrix(x0',sort(pin_I)');
    
    % Plotting pinned vertices.
    X_plot=plot3(x(1,pin_I),x(2,pin_I),x(3,pin_I),'.','Color','red','MarkerSize',20);
    hold on;
    
    % Sampling points used to compute energies.
    if config.sample_interior
        [V, vol] = raycast_quadrature(parts, [3 3], 10);
    else
    	V=x0;
        vol=ones(size(V,2),1);
    end
    m = size(V,2);  % number of quadrature points
    
    % TODO: add option to visualization quadrature points
    V_plot=plot3(V(1,:),V(2,:),V(3,:),'.','Color','m','MarkerSize',20);
    
    % Lame parameters concatenated.
    params = [config.mu * 0.5, config.lambda * 0.5];
    params = repmat(params,size(V,2),1);
        
    % Gravity force vector.
  	f_gravity = repmat([0 0 config.gravity], size(x0,2),1)';
    f_gravity = config.dt*P*f_gravity(:);
            
    % Shape Matrices
    L = compute_shape_matrices_newcom(x0, x0_coms, com_map, E, adjacent, ...
        config.order, config.fitting_mode);
    %     nnz(L)
    Lz = abs(L(:)) < 1e-12;
    L(Lz) = 0;
    L=sparse(L);

    % Compute Shape weights
    w = nurbs_blending_weights(parts, V', config.distance_cutoff, ...
                               config.enable_secondary_rays);
    w_x = nurbs_blending_weights(parts, x0', config.distance_cutoff, ...
                                 config.enable_secondary_rays);

    % TODO support truncated!
    [W, W_I, W_S] = build_weight_matrix(w, d, k, 'Truncate', false);
    [W0, W0_I, W0_S] = build_weight_matrix(w_x, d, k, 'Truncate', false);
                             

    % Build Monomial bases for all quadrature points
    Y = monomial_basis_matrix(V, x0_coms, w, W_I, config.order, k);
    Y0 = monomial_basis_matrix(x0, x0_coms, w_x, W0_I, config.order, k);

    
    % Fixed x values.
    x_fixed = zeros(size(x0));
    for i = 1:numel(pin_I)
        x_fixed(:,pin_I(i))=x0(:,pin_I(i));
    end
    
    % Applying fixed point constraints to NURBS jacobian.
    J = P * J;    
    
    % Forming gradient of monomial basis w.r.t X
    dF_dc = monomial_basis_grad_matrix(V, x0_coms, w, W_I, config.order, k);
    
    % Computing each gradient of deformation gradient with respect to
    % projection operator (c are polynomial coefficients)
%     dF_dc = vem_dF_dc(dM_dX, W);

    % Compute mass matrices
    ME = vem_error_matrix(Y0, W0, W0_S, L, w_x, E);
    M = vem_mass_matrix(Y, W, W_S, L, config.rho .* vol);
    M = (M + config.k_stability*ME); % sparse?
    % Save & load these matrices for large models to save time.
    % save('saveM.mat','M');
    % save('saveME.mat','ME');
    % M = matfile('saveM.mat').M;
    % ME = matfile('saveME.mat').ME;
   
    ii=1;
    for t=0:config.dt:30
        tic
        % Recompute shape coms
        for i=1:n
            x_coms(:,i) = mean(x(:,adjacent{i}),2);
        end

        % Preparing input for stiffness matrix mex function.
        b = [];
        for i=1:numel(E)
            b = [b (x(:,E{i}))];
        end
        b = b(:);

        % Solve for polynomial coefficients (projection operators).
        c = L * b;
        
        % Stiffness matrix (mex function)
%         K = -vem3dmesh_neohookean_dq2(c, dM_dX(:,:), vol, params, ...
%                                       dF_dc, W, W_S, W_I, k, n);
%         K = L' * K * L;

        % Force vector
        K = zeros(d*(k+1)*numel(E), d*(k+1)*numel(E));
        dV_dq = zeros(d*(k+1)*numel(E),1);

        % Computing force dV/dq for each point.
        % TODO: move this to C++ :)
        for i = 1:m
            
            % Deformation Gradient
            F = dF_dc{i} * c;
            F = reshape(F,d,d);
            
            V(:,i) = Y{i} * c;
            
            % Force vector
            dV_dF = neohookean_tet_dF(F, params(i,1), params(i,2));
            dV_dq = dV_dq +  dF_dc{i}' * dV_dF * vol(i);
            
            % Stiffness matrix contribution
            d2V_dF2 = neohookean_tet_dF2(F, params(i,1), params(i,2));
%             K = K - W_S{i}' * dF_dc{i}' * d2V_dF2 * dF_dc{i} * W_S{i};
            K = K - dF_dc{i}' * d2V_dF2 * dF_dc{i};
        end
        K = L' * K * L;
        dV_dq = L' * dV_dq;
        
        % Error correction force
        x_centered = x(:);
        f_error = - 2 * ME * x_centered;
        f_error = 0*config.k_stability*(config.dt * P * f_error(:));
       
        % Force from potential energy.
        f_internal = -config.dt*P*dV_dq;
%         f_internal=0;K=0;
        % Computing linearly-implicit velocity update

        lhs = J' * (P*(M - config.dt*config.dt*K)*P') * J;
%         lhs = J' * (P*(M - config.dt*config.dt*(K+ME))*P') * J;
        rhs = J' * (P*M*P'*J*qdot + f_internal + f_gravity + f_error);
        qdot = lhs \ rhs;

        % Update position
        q = q + config.dt*qdot;
        x = reshape(P'*J*q,3,[]) + x_fixed;

        % Update NURBs plots
        x_idx=0;
        for i=1:numel(parts)
            x_sz = size(parts{i}.x0,2);
            xi = x(:,x_idx+1:x_idx+x_sz);
            parts{i}.plt.Vertices =xi';
            x_idx = x_idx+x_sz;
        end
        
        com_plt.XData = x_coms(1,:);
        com_plt.YData = x_coms(2,:);
        com_plt.ZData = x_coms(3,:);
        
        V_plot.XData = V(1,:);
        V_plot.YData = V(2,:);
        V_plot.ZData = V(3,:);
        drawnow
        
        if config.save_obj
            obj_fn = "output/obj/part_" + int2str(ii) + ".obj";
            nurbs_write_obj(q,parts,obj_fn,ii);
        end
        
        if config.save_output
            fn=sprintf('output/img/simulate_%03d.png',ii);
            saveas(fig,fn);
        end
        ii=ii+1
        toc
    end
end
