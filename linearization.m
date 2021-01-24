% Evaluate system of equations at linearization points

path_to_balloon_library = './balloon_library';
balloon_name = 'HAB-2000';
addpath(path_to_balloon_library); % import balloon configuration files
balloon_parameters = import_balloon(balloon_name);

target_altitude = 24000; % [m] target altitude

lift_gas = balloon_parameters.spec.lifting_gas;
M = molar_mass(lift_gas); % [kg/mol] molar mass of lifting gas
balloon_drag_coeff = balloon_parameters.spec.drag_coefficient; % coefficient of drag

balloon_mass = balloon_parameters.spec.mass.value; % [kg] mass of the balloon
payload_dry_mass  = 1.427;  % [kg]
ballast_mass   = 0.0; % [kg]
total_dry_mass = balloon_mass + ballast_mass + payload_dry_mass; % [kg] total mass without the gas
m_gas = gas_for_equilibrium(total_dry_mass, lift_gas, target_altitude); % [kg] mass of lift gas needed for equilibrium

% linearization point
x_e = target_altitude
xdot_e = 0
mgas_e = m_gas
mballast_e = ballast_mass

xdotdot = evaluate_accel(x_e, xdot_e, mgas_e, mballast_e, balloon_mass, payload_dry_mass, balloon_drag_coeff, lift_gas)

A = evaluate_jacobian(x_e, xdot_e, mgas_e, mballast_e, balloon_mass, payload_dry_mass, balloon_drag_coeff, lift_gas)
B_bleed = [0;0;1;0];
B_ballast = [0;0;0;1];
C=[1 0 0 0;
   1 0 0 0;
   0 1 0 0;
   0 0 0 1/9.80665];
D=0;

ts=0.1;
sys_bleed_continuous = ss(A,B_bleed,C,D)
sys_ballast_continuous = ss(A,B_ballast,C,D)
sys_bleed_discrete = ss(A,B_bleed,C,D,ts)
sys_ballast_discrete = ss(A,B_ballast,C,D,ts)

observability = obsv(sys_bleed_continuous)
fprintf('observable: %d\n', rank(observability)>=4);

controllability_bleed = ctrb(sys_bleed_continuous); % get the controllability matrix
fprintf('controllable (bleed): %d\n', rank(controllability_bleed)>=4);
controllability_ballast = ctrb(sys_ballast_continuous); % get the controllability matrix
fprintf('controllable (ballast): %d\n', rank(controllability_ballast)>=4);
