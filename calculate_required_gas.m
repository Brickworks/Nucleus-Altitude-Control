function [required_gas_mass] = calculate_required_gas(dry_mass, gas_species, ref_altitude)
%calculate_required_gas Calculate the amount of gas (kg) needed to sustain
% a given dry mass (kg) at equilibrium.
%   Calculate the amount of a gas (e.g. helium) that is required to lift a
%   payload mass such that the net force (N), not including drag, is zero
%   at the desired altitude (m).
M = molar_mass(gas_species);
[T, ~, P, Rho_atmo] = atmoscoesa(ref_altitude);
R = 3.022e23*1.38e-23;
Rho_gas = (P*M)/(R*T);
% V = R * (gas_mass/M) * T / P; <-- we can use V to find gas_mass

% <-- forces are positive UP -->

% weight (for reference)
% earth_radius = 6371007.2;
% gravity = -9.80665 * (earth_radius/(earth_radius + ref_altitude))^2;
% weight_force = dry_mass * gravity;

% buoyancy
density_diff = Rho_gas - Rho_atmo; % <-- this term is negative, 
%                                        but we multiply by g which is
%                                        also negative
% buoyancy_force = V * density_diff * gravity; <-- we need to calculate V

% net force
% 0 = buoyancy_force + weight_force;
% 0 = V * density_diff * gravity + dry_mass * gravity; 
% 0 = V * density_diff + dry_mass; <-- factor out g and divide both sides
% R * (gas_mass/M) * T / P = -dry_mass / density_diff; <-- expand terms
required_gas_mass = (-dry_mass / density_diff) * P * M / (R * T);
end

