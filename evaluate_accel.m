function xdotdot = evaluate_accel(x, xdot, m_gas, m_ballast, m_balloon, m_dry, Cd, gas_species)
% universal constants
R = 3.022e23*1.38e-23;
g_0 = -9.80665;
r_Earth = 6371007.2;

% circumstantial constants
M = molar_mass(gas_species);
[T, ~, P, rho_ambient] = atmoscoesa(x);

% put it all together
xdotdot = g_0 * (r_Earth/(r_Earth+x))^2 + (-sign(xdot)*xdot^2*Cd * 1/2 * pi * ((m_gas*(R*T)/(M*P))/(pi*4/3))^(2/3))/(m_balloon + m_ballast + m_dry) + (g_0 * (r_Earth/(r_Earth+x))^2 * m_gas*(R*T)/(M*P)*((M*P)/(R*T) - rho_ambient))/(m_balloon + m_ballast + m_dry);
end 

