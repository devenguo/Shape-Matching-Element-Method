function linear_rounded_cube

function pinned_ids = pin_function(x)
    verts_to_pin = 4; 
    [~,I] = mink(x(3,:),verts_to_pin);
    pinned_ids = I(1:verts_to_pin);
end

iges_file = 'rounded_cube.iges';
part = nurbs_from_iges(iges_file);

YM = 1e2; %in Pascals
pr =  0.15;
[lambda, mu] = emu_to_lame(YM, pr);

options.order = 1;
options.rho = 1e-1;
options.gravity = -10;
options.pin_function = @pin_function;
options.lambda = lambda;
options.mu = mu;

vem_simulate_nurbs_newtons(part, options);
% vem_simulate_nurbs(part, options);

end