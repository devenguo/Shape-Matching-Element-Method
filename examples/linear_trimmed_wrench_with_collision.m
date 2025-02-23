function linear_trimmed_wrench_with_collision

function pinned_ids = pin_function(x)
    verts_to_pin = 2; 
    [~,I] = mink(x(1,:),verts_to_pin);
    pinned_ids = I(1:verts_to_pin);
end

iges_file = 'wrench.iges';

part = nurbs_from_iges(iges_file);


YM = 2e3; %in Pascals
pr =  0.25;
[lambda, mu] = emu_to_lame(YM, pr);

options.order = 1;
options.rho = 1;
options.pin_function = @pin_function;
options.lambda = lambda;
options.mu = mu;
options.gravity = 0;

options.sample_interior = 0;
options.collision_ratio = 1.0;
options.collision_with_other = true;
options.self_collision = false;
options.collision_with_plane = true;
options.collision_plane_z = -40.0;

vem_simulate_nurbs_with_collision(part, options);
end