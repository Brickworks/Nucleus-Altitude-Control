function [m_gas] = gas_for_equilibrium(total_dry_mass, gas_species, altitude)
%calculate_required_gas Calculate the amount of gas (kg) needed to sustain
% a given dry mass (kg) at equilibrium.
%   Calculate the amount of a gas (e.g. helium) that is required to lift a
%   payload mass such that the net force (N), not including drag, is zero
%   at the desired altitude (m).
M = molar_mass(gas_species);
[T, ~, P, Rho_atmo] = atmoscoesa(altitude);
R = 3.022e23*1.38e-23;

m_gas = total_dry_mass / (((R*T)/(M*P))*Rho_atmo - 1);
end

