function [q, J] = nurbs_coords(srf, UV)
    % generalized coordinates
    q = zeros(3*size(srf.coefs,2)*size(srf.coefs,3), 1);

    for i=1:size(srf.coefs,2)
        for j = 1:size(srf.coefs,3)
            idx = 3*(size(srf.coefs,3)*(i-1) + (j-1)) + 1;
            q(idx:idx+2) = srf.coefs(1:3,i,j);
        end
    end
    
    n = size(UV,2);
    J = zeros(n, 3, 3 * prod(srf.number));
    degree = srf.order-1; 
    % Building J matrices (one for each u,v pair)
    for i=1:n
        u = UV(1,i);
        v = UV(2,i);
        si = findspan(srf.number(1)-1, degree(1), u, srf.knots{1});
        Ni = basisfun(si, u, degree(1), srf.knots{1});
        
        sj = findspan(srf.number(2)-1, degree(2), v, srf.knots{2});
        Nj = basisfun(sj, v, degree(2), srf.knots{2});

        % outerproduct of B spline values in u & v directions
        % row-wise ordering of matrices in J with u being the row index
        Nij = Ni'*Nj;
        w = srf.coefs(4, si+1-degree(1):si+1, sj+1-degree(2):sj+1);

        % Nij is (degree(1)+1 x degree(2)+1) matrix.
        % Bspline decays to zero outside its local support so Nij
        % contains only these nonzero values.
        Nij = Nij .* squeeze(w);
        Nij = Nij ./ sum(Nij,'all');
        for ki=1:size(Nij,1)
            for kj=1:size(Nij,2)
                Jij = diag(repelem(Nij(ki,kj),3));
                k = 3*((si-degree(1)+ki-1) * srf.number(2) + (sj-degree(2)+kj-1))+1;
                J(i,:,k:k+2) = Jij;
            end
        end
    end
end
