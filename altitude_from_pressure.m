function H = altitude_from_pressure(P, b)
R = 287.053; % [J/kg/K] gas constant (air)
g0 = 9.80665; % [m/s^2] standard gravity

% Hb [km]    geopotential height at base of layer b
% Lb [K/km]  lapse rate across layer b
% Pb [Pa]    static pressure at base of layer b
% Tb [K]     temperature at base of layer b

if b == 0
    Hb = 0; 
    Lb = -6.5e-3;
    Pb = 101325;
    Tb = 288.15;
elseif b == 1
    Hb = 11000; 
    Lb = 0.0;
    Pb = 22632.06;
    Tb = 216.65;
elseif b == 2
    Hb = 20000; 
    Lb = 1.0e-3;
    Pb = 5474.889;
    Tb = 216.65;
elseif b == 3
    Hb = 32000; 
    Lb = 2.8e-3;
    Pb = 868.0187;
    Tb = 228.65;
elseif b == 4
    Hb = 47000; 
    Lb = 0.0;
    Pb = 110.9063;
    Tb = 270.65;
elseif b == 5
    Hb = 51000; 
    Lb = -2.8e-3;
    Pb = 66.93887;
    Tb = 270.65;
elseif b == 6
    Hb = 71000; 
    Lb = -2.0e-3;
    Pb = 3.956420;
    Tb = 288.15;
elseif b == 7
    Hb = 84852; 
    Lb = nan;
    Pb = 0.3734;
    Tb = 186.87;
else
    Hb = nan; 
    Lb = nan;
    Pb = nan;
    Tb = nan; 
end

if isnan(Lb)
    H = nan;
elseif Lb == 0
    H = Hb - log(P/Pb)*R*Tb/g0;
else
    T = Tb * (P/Pb)^(-Lb*R/g0);
    H = Hb + (T - Tb) / Lb;
end
end
