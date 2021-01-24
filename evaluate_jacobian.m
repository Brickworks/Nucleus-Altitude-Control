function [J] = evaluate_jacobian(x, xdot, m_gas, m_ballast, m_balloon, m_dry, Cd, gas_species)
% universal constants
R = 3.022e23*1.38e-23;
g_0 = -9.80665;
r_Earth = 6371007.2;

% circumstantial constants
M = molar_mass(gas_species);
[T, ~, P, rho_ambient] = atmoscoesa(x);

% interesting partial diffs
dx1 = -2*g_0*r_Earth^2 / (r_Earth + x)^3 * (1 + (m_gas*(R*T)/(M*P)*((M*P)/(R*T) - rho_ambient)) / (m_balloon + m_ballast + m_dry));
dx2 = -xdot * sign(xdot) * (Cd*pi*(((m_gas*R*T)/(M*P) * (4/3*pi)^-1 )^(2/3))/(m_balloon + m_ballast + m_dry));
dx3 = (R*T)/(M*P*(m_balloon + m_ballast + m_dry)) * (g_0 * (r_Earth/(r_Earth+x))^2 * ((M*P)/(R*T) - rho_ambient)-(sign(xdot)*Cd*xdot^2*(pi/6)^(1/3))/(2*(m_gas*R*T/(M*P))^(1/3)));
dx4 = ((sign(xdot)*xdot^2*pi*Cd*(m_gas*R*T/(M*P)*(4/3*pi)^(-1))^(2/3))/(2*(m_balloon + m_ballast + m_dry)^2)) - ((g_0 * (r_Earth/(r_Earth+x))^2*(m_gas*(R*T)/(M*P)*((M*P)/(R*T) - rho_ambient))/((m_balloon + m_ballast + m_dry)^2)));

% assemble the jacobian
J = [0 1 0 0;
     dx1 dx2 dx3 dx4;
     0 0 0 0;
     0 0 0 0];
end

