function gas_mass = get_recommended_fill_mass(free_lift, gas_species, total_dry_mass)
%get_recommended_fill_mass Calculate the amount of lift gas (kg) that is
% required in order to make the target free lift (kg) at sea level.
%   Args:
%       gas_species (string)            the type of lift gas used
%       free_lift (double)              the target free lift (kg)
%       total_dry_mass (double)         total mass not including gas (kg)

M = molar_mass(gas_species);
[T, ~, P, Rho_atmo] = atmoscoesa(0);
R = 3.022e23*1.38e-23;
Rho_gas = (P*M)/(R*T);
% V = R * (gas_mass/M) * T / P; <-- we can use V to find gas_mass

% <-- forces are positive UP -->

% weight (for reference)
% earth_radius = 6371007.2;
% gravity = -9.80665 * (earth_radius/(earth_radius + ref_altitude))^2;
% weight_force = dry_mass * gravity;

% gross lift
density_diff = Rho_atmo - Rho_gas; % <-- we arrange this to be positive
% gross_lift = V * density_diff; <-- we need to calculate V

% free lift
% free_lift = gross_lift - total_dry_mass;
% free_lift = V * density_diff - total_dry_mass;
% free_lift = R * (gas_mass/M) * T / P * density_diff - total_dry_mass;
% R * (gas_mass/M) * T / P * density_diff = free_lift + total_dry_mass;
gas_mass = (free_lift + total_dry_mass) / (R * (1/M) * T / P * density_diff);
end

