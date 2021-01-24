% sensor characteristics
BMP388_altitude_variance = 6.9113; % variance of derived altitude over a typical uncontrolled flight
MAXM8_altitude_variance = (2.5*1.7)^2; % datasheet accuracy: 2.5 m RMS horizontal position, assume 1.7x worse for vertical position
MAXM8_velocity_variance = (0.05)^2; % datasheet accuracy: 0.05 m/s RMS
XXXX_load_variance = 0.001^2; % datasheet accuracy: 0.01 N RMS

% state space model
dt = 0.01; % [s] time step
LP_altitude = 24000; % [m] linearization point altitude
LP_velocity = 0; % [m/s] linearization point velocity
LP_mgas = 1.3032; % [kg] linearization point gas mass
LP_mballast = 0; % [kg] linearization point ballast mass
xLP = [LP_altitude; LP_velocity; LP_mgas; LP_mballast]; % linearization state
A = [0 1 0 0;
     0 0 7.4687 -2.8401;
     0 0 0 0;
     0 0 0 0];
B = [0 0;
     0 0;
     1 0;
     0 1];
C = [1 0 0 0;
     1 0 0 0;
     0 1 0 0;
     0 0 0 9.80665];
D=0;
sys = ss(A,B,C,D); % continuous time
sysd = c2d(sys,dt) % discrete time

% noise covariance
R = [BMP388_altitude_variance MAXM8_altitude_variance MAXM8_velocity_variance XXXX_load_variance] % measurement noise
Q = 1 * ones(1,4) % process noise
P0 = ones(1,4) % initial error covariance

% initial values
initial_altitude = 20000 % [m] initial altitude above sea level
initial_velocity = 5 % [m/s] initial vertical velocity
balloon_fill_mass = 1.8812 % [kg] gas in the balloon
consumable_mass   = 1.0 % [kg] ballast in the hopper
x0 = [initial_altitude; initial_velocity; balloon_fill_mass; consumable_mass] % initial states

%% STEP 1 - no input
u = [0; 0];
y = [initial_altitude; initial_altitude; initial_velocity; consumable_mass/9.81;]
[x0,P0,K]=kf(x0,u,y,sysd.A,sysd.B,sysd.C,P0,Q,R,xLP); %run kf for one time step

function [xhat,P,K] = kf(x0,u,y,A,B,C,P0,Q,R,xLP)
R=diag(R); Q=diag(Q); P0=diag(P0);
% PREDICT
dxhatp = A*(x0-xLP) + B*u % predicted next delta state estimate
Pp = A*P0*A'+Q % predicted error covariance

% GAIN
K = (Pp*C')/(C*Pp*C'+R) % kalman gain

% UPDATE
P = (eye(4)-K*C)*Pp % actual error covariance
dxhat = dxhatp + K*((y-xLP)-C*dxhatp) % actual delta state estimate
xhat = xLP+dxhat % actual state estimate
end