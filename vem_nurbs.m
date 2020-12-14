function vem_nurbs
    % Simulation parameters
    dt = 0.01;      	% timestep
    C = 0.5 * 1700;   	% Lame parameter 1
    D = 0.5 * 15000;   	% Lame parameter 2
    gravity = -100;
    k_error = 100000;
    order = 1;
    rho = 1;
    save_output = 0;
    save_obj = 0;
    obj_res = 15;

    % Read in tetmesh
    [V,I] = readNODE([data_dir(), '/meshes_tetgen/Puft/head/coarsest.1.node']);
    [T,~] = readELE([data_dir(), '/meshes_tetgen/Puft/head/coarsest.1.ele']);
    %     [V,I] = readNODE('C:\Users\TY\Desktop\tetgen1.6.0\build\Release\rocket.1.node');
    %     [T,~]  = readELE('C:\Users\TY\Desktop\tetgen1.6.0\build\Release\rocket.1.ele');
    E = boundary_faces(T);
    vol = volume(V,T);
       
    % Swap y&z and flip z axis
    V=V';
    V([2 3],:)=V([3 2],:);
    V(3,:) = -V(3,:);

    % Read in NURBs 
    fig=figure(1);
    clf;
        
    part=nurbs_from_iges('rocket_4.iges',6,0);
%     res=repelem(5,14); res(1)=8;
%     part=nurbs_from_iges('rocket_4.iges',res,0);
%     part=nurbs_from_iges('rounded_cube.iges',6,0);
%     part=nurbs_from_iges('castle_simple.iges',6,0);
%     res=[8 20];
%     part=nurbs_from_iges('mug.iges',res,1);
    part=plot_nurbs(part);
    
    x0 = zeros(3,0);
    q_size = 0;
    J_size = 0;
    
    % build global position vectors
    for i=1:numel(part)
        idx1=q_size+1;
    	q_size = q_size + size(part{i}.p,1);
        J_size = J_size + size(part{i}.J_flat,2) * size(part{i}.J_flat,3);
        idx2=q_size;
        
        % indices into global configuration vector
        part{i}.idx1=idx1;
        part{i}.idx2=idx2;
    end
    
    q = zeros(q_size,1);
    J = zeros(J_size,q_size);
    J_idx = [0 0];
    for i=1:numel(part)
        q(part{i}.idx1:part{i}.idx2,1) = part{i}.p;
        Ji = part{i}.J_flat(:,:)';
        
        % Block indices
        I1=J_idx(1)+1:J_idx(1)+size(Ji,1);
        I2=J_idx(2)+1:J_idx(2)+size(Ji,2);
        
        % Subsitute block into global NURBs jacobian (J) matrix
        J(I1,I2) = Ji;
        J_idx = J_idx + size(Ji);
        size(Ji)
    end
    J = sparse(J);
    qdot=zeros(size(q));
    E=cell(numel(part),1);
    
    for i=1:numel(part)
        idx1=size(x0,2)+1;
        x0 = [x0 part{i}.x0];
        idx2=size(x0,2);
        
        % indices into global configuration vector
        E{i}=idx1:idx2;
    end

    % Initial deformed positions and velocities
    x = x0;
    
    % Setup pinned vertices constraint matrix
    [kth_min,I] = mink(x0(3,:),20);
    pin_I = I(1:12);
    % pin_I = find(x0(3,:) < 2);
    pin_I = find(x0(1,:) > 6 & x0(3,:) > 6 & x0(3,:) < 8);
    % pin_I = find(x0(1,:) > max(x0(1,:)) - 1e-4);
    P = fixed_point_constraint_matrix(x0',sort(pin_I)');
    
    % Plot all vertices
    X_plot=plot3(x(1,pin_I),x(2,pin_I),x(3,pin_I),'.','Color','red','MarkerSize',20);
    hold on;
    %V=[V x0];
    V=x0;
    %plot3(V(1,:),V(2,:),V(3,:),'.');

    % Gravity force vector.
  	f_gravity = repmat([0 0 gravity], size(x0,2),1)';
    f_gravity = dt*P*f_gravity(:);
    
    % Undeformed Center of mass
    x0_com = mean(x0,2);
        
    % Shape Matrices
    %E=cell(1);
    %E{1}=1:size(x0,2);
    [B,~] = compute_shape_matrices(x0, x0_com, E, order);
    
    % Build Monomial bases for all quadrature points
    Q = monomial_basis(V, x0_com, order);
    Q0 = monomial_basis(x0, x0_com, order); 
    
    % Compute Shape weights
    % a = compute_projected_weights(x0, E, V);
    % a_x = compute_projected_weights(x0, E, x0);
    
    a = nurbs_diffusion_weights(part, V);
    a_x = nurbs_diffusion_weights(part, x0);
    
    % Form selection matrices for each shape.
    S = cell(numel(E),1);
    for i=1:size(E,1)
        S{i} = sparse(zeros(numel(x0), numel(E{i})*3));
        for j=1:numel(E{i})
            idx = E{i}(j);
            S{i}(3*idx-2:3*idx,3*j-2:3*j) = eye(3);
        end
    end
    
    % Fixed x values.
    x_fixed = zeros(size(x0));
    for i = 1:numel(pin_I)
        x_fixed(:,pin_I(i))=x0(:,pin_I(i));
    end
    
    J = P * J;
    m = size(Q,2);
    
    % Forming gradient of monomial basis w.r.t X
    dM_dX = monomial_basis_grad(V, x0_com, order);
    
    % Computing gradient of deformation gradient w.r.t configuration, q
    d = 3;  % dimension (2 or 3)
    dF_dq = vem_dF_dq(B, dM_dX, E, size(x,2), a);
    dF_dq = permute(dF_dq, [2 3 1]);
    SdF = cell(m,1);
    dF = cell(m,1);
    dF_I = cell(m,1);
    for i = 1:m
       m1 = dF_dq(:,:,i);
       mm1 = max(abs(m1),[],1);
       I = find(mm1 > 1e-4);
       [~,I] = maxk(mm1,60);
       m1(:,setdiff(1:numel(x),I))=[];
       sum(mm1 < 1e-4)
       %sum(mm1 < 1e-5)
       dF_I{i} = I';
       SdF{i} = sparse(zeros(numel(I), numel(x)));
       ind=sub2ind(size(SdF{i}), 1:numel(I),I);
       SdF{i}(ind)=1;
       dF{i} = m1;
    end

    % Compute mass matrices
    ME = vem_error_matrix(B, Q0, a_x, d, size(x,2), E);
    M = vem_mass_matrix(B, Q, a, d, size(x,2), E);
    M = ((rho*M + k_error*ME)); %sparse?, doesn't seem to be
%     save('saveM.mat','M');
%     save('saveME.mat','ME');
% 	M = matfile('saveM.mat').M;
% 	ME = matfile('saveME.mat').ME;
    %     M = rho * eye(numel(x0));
    
    k=3;
    if order == 2
        k = 9;
    end
        
    ii=1;
    for t=0:dt:30
        tic
        x_com = mean(x,2);
        
        % Compute shape matching matrices
        A=zeros(d, k, numel(E));
        for i=1:numel(E)
            p = x(:,E{i}) - x_com;
            Ai = p*B{i};
            A(:,:,i) = Ai;
        end
        
        dV_dq = zeros(numel(x),1);     % force vector
        K0 = zeros(numel(x), numel(x)); % stiffness matrix
        
        % Computing force dV/dq for each point.
        n=size(x0,2);
        dF_dqij = permute(dF_dq, [3 1 2]);
        Aij = permute(A, [3 1 2]);
        Aij = Aij(:,:);        
        vol=ones(size(a,1),1);
        params = [C, D];
        params = repmat(params,size(a,1),1);
        
        % Force vector
        K = -vem3dmesh_neohookean_dq2(Aij, dF_dqij(:,:), dM_dX(:,:), a, vol, params,k,n,dF,dF_I);

        % Computing force dV/dq for each point.
        for i = 1:m
            dMi_dX = squeeze(dM_dX(i,:,:));
            
            Aij = zeros(size(A(:,:,1)));
            
            for j = 1:size(E,1)
                Aij = Aij + A(:,:,j) * a(i,j);
            end
            
            % Deformation Gradient
            F = Aij * dMi_dX;
                        
            % Force vector
            dV_dF = neohookean_tet_dF(F,C,D);

            dV_dq = dV_dq + dF_dq(:,:,i)' * dV_dF; % assuming constant area

            % Stiffness matrix
            %d2V_dF2 = neohookean_tet_dF2(F,C,D);
            %K0 = K0 - dF_dq(:,:,i)' * d2V_dF2 * dF_dq(:,:,i);
        end
        %diff = K-K0;
        %norm(diff(:))
        
        % Error correction force
        f_error = - 2 * ME * x(:);
        f_error = k_error*(dt * P * f_error(:));
       
        % Force from potential energy.
        f_internal = -dt*P*dV_dq;
        
        % Computing linearly-implicit velocity update
        lhs = J' * (P*(M - dt*dt*K)*P') * J;
        rhs = J' * (P*M*P'*J*qdot + f_internal + f_gravity + f_error);
        qdot = lhs \ rhs;

        % Update position
        q = q + dt*qdot;
        x = reshape(P'*J*q,3,[]) + x_fixed;
        
        % Update NURBs plots
        x_idx=0;
        for i=1:numel(part)
            x_sz = size(part{i}.x0,2);
            xi = reshape(x(:,x_idx+1:x_idx+x_sz), 3, part{i}.subd(1), part{i}.subd(2));
            part{i}.plt.XData = squeeze(xi(1,:,:));
            part{i}.plt.YData = squeeze(xi(2,:,:));
            part{i}.plt.ZData = squeeze(xi(3,:,:));
            x_idx = x_idx+x_sz;   
        end
        drawnow
        
        if save_obj
            obj_fn = "output/obj/part_" + int2str(ii) + ".obj";
            nurbs_write_obj(q,part,obj_res,obj_fn,ii);
        end
        
        if save_output
            fn=sprintf('output/img/img_%03d.png',ii);
            saveas(fig,fn);
        end
        ii=ii+1
        toc
    end
end
