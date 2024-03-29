%% Configure and Run Simulation
% 1. Set all user parameters in each configuraiton section below.
% 2. Run the script.
% ------------------------------------------------------------------------- 
%% Model Options
% Configure the simulation environment.
% -------------------------------------------------------------------------
%   path_to_balloon_library     The path to the directory that
%                               contains JSON files corresponding
%                               to known balloon specifications.
%
%   dt                          Duration of a single time step (seconds).
%   
%   initial_altitude            The altitude of the HAB at the start of
%                               the simulation.
%   
%   initial_velocity            The vertical velocity of the HAB at the
%                               start of the simulation.
% -------------------------------------------------------------------------
%% Tunable Parameters & Controller Options
% Configure adjustable characteristics of the balloon.
% -------------------------------------------------------------------------
%   balloon_name                The alphanumeric part number that
%                               identifies the specific model of balloon
%                               to use. Example: 'HAB-2000'
%
%   balloon_fill_mass           Mass of lift gas (kg) contained inside the
%                               balloon at the start of the simulation.
%
%   reserved_gas_mass           Amount of lift gas (kg) to reserve in the
%                               balloon, which the altitude controller
%                               is not permitted to bleed for corrections.
%
%   consumable_mass             Total mass (kg) of consumable material 
%                               below the neck of the balloon at the start 
%                               of the simulation.
% -------------------------------------------------------------------------
% Configure adjustable parameters specific to the altitude controller.
% -------------------------------------------------------------------------
%   target_altitude             The altitude (m) to maintain when the
%                               controller is active.
%   
%   delay_time                  Time (s) to wait after the start of the
%                               simulation before starting the controller.
% 
%   delay_altitude              Minimum altitude (m) to reach before
%                               starting the controller.
%   
%   max_safe_error              The maximum deviation (m) of altitude from
%                               the target altitude. If the error is larger
%                               than this value, the controller is
%                               turned off.
%
%   max_deadzone_error          The allowable deviation (m) of altitude 
%                               from the target altitude before the
%                               controller takes action to correct.
%
%   Kp                          Gain applied to proportional error.
%
%   Ki                          Gain applied to integral error.
%
%   Kd                          Gain applied to derivative error.
% 
%   Kn                          Gain applied to the filter on the
%                               derivative error.
%
%   Kb                          Gain applied to the anti-windup
%                               back-calculation.
% -------------------------------------------------------------------------
path_to_nctoolbox = '../nctoolbox-1.1.0'; % github.com/nctoolbox/nctoolbox
path_to_balloon_library = './balloon_library';
dt = 0.01; % [s] simulation step time
use_std_atmo = true; % if true, use COESA. else retrieve weather from GFS.

% start location: Reno, NV
initial_latitude = 39.5296; % [deg] initial latitude
initial_longitude = -119.8138; % [deg] initial longitude
initial_altitude = 1373; % [m] initial altitude above sea level
initial_velocity = 0; % [m/s] initial vertical velocity
initial_time = '2021-02-22 17:00:00'; % UTC time

balloon_name = 'HAB-1200';

% altitude controller settings
target_altitude = 24000; % [m] target altitude
min_altitude_limit = 15000; % [m] abort if below this altitude after starting control
max_deadzone_error = 100; % [m] don't actuate if error is smaller than this
max_deadzone_speed = 0.2; % [m/s] don't actuate if ascent rate is smaller than this
max_allowed_error = 1000; % [m] only allow control if altitude error is smaller than this
delay_time = 500; % [s] time to wait after launch before starting controller
delay_altitude = max(target_altitude-max_allowed_error,min_altitude_limit); % [m] altitude to reach before arming

% mass properties
extra_gas_above_reserve = 0.5; % [kg]
gas_reserve_buffer_above_equilibruim = 0.001; % [kg]
payload_dry_mass  = 1.427;  % [kg]
consumable_mass   = 0.5; % [kg]

% aerodynamics
box_area = 0.2 * 0.2;     % [m^2]
box_drag_coeff = 0.8;
parachute_area = 1.1;     % [m^2]
parachute_drag_coeff = 1.3;

% hardware limits
parachute_open_altitude = 18000; % [m]
mdot_ballast = 0.0100; % [kg/s]
mdot_ballast_noise_power = 0.0001; % multiplied against mdot to emulate variability
mdot_bleed = 0.010; % [kg/s]
mdot_bleed_noise_power = 0.0001; % multiplied against mdot to emulate variability

% PID settings
Dump.Kp = 1e-8; % Proportional Gain
Dump.Ki = 1e-5; % Integral Gain
Dump.Kd = 1e-3; % Derivative Gain
Dump.Kn = 1e-1; % Derivative Filter Gain
Dump.Kb = 0e-1; % Anti Windup Back-calculation Gain

Vent.Kp = 1e-5; % Proportional Gain
Vent.Ki = 0e-5; % Integral Gain
Vent.Kd = 1e-3; % Derivative Gain
Vent.Kn = 1e-1; % Derivative Filter Gain
Vent.Kb = 0e-1; % Anti Windup Back-calculation Gain

pwm_period = 1; %[s] period of the pwm controller

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% SIMULATION INITIALIZATION %%
% This is the code that sets up the simulation and kicks it off.
% Do not change anything below this line!
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if ~use_std_atmo
    % Initialize weather data
    addpath(path_to_nctoolbox);
    setup_nctoolbox;

    % Create atmosphere lookup tables
    disp('Getting data from GFS...');
    gfs_latlon_bounding_box = [-125 -66, 50, 24]; % continental USA
    [gfsIsobaricDataCubes, latIndex, lonIndex, gfsVarIndex] = get_gfs_data(initial_time, gfs_latlon_bounding_box);

    altitudeVsPressure = gfsIsobaricDataCubes(ismember(gfsVarIndex, 'HGT'),:); % [m]
    temperatureVsPressure = gfsIsobaricDataCubes(ismember(gfsVarIndex, 'TMP'),:); % [K]
    uWindVsPressure = gfsIsobaricDataCubes(ismember(gfsVarIndex, 'UGRD'),:); % [m/s]
    vWindVsPressure = gfsIsobaricDataCubes(ismember(gfsVarIndex, 'VGRD'),:); % [m/s]
    zWindVsPressure = gfsIsobaricDataCubes(ismember(gfsVarIndex, 'DZDT'),:); % [m/s]

    interpAltitude = linspace(1,40000,length(altitudeVsPressure{1}));

    disp('Interpolating pressure vs altitude...');
    pressureVsAltitude = nan(length(latIndex),length(lonIndex),length(interpAltitude));
    for j=1:length(latIndex)
        for k = 1:length(lonIndex)
            altitudeVsPressure_latlon = interp3d_at_coordinate(altitudeVsPressure{2},latIndex,lonIndex,altitudeVsPressure{1},latIndex(j),lonIndex(k));
            pressureVsAltitude(j,k,:) =  interp1(altitudeVsPressure_latlon,altitudeVsPressure{1},interpAltitude, 'linear', 'extrap')'; % [Pa]
        end
    end

    % only consider the lat long air column
    altitudeVsPressure_latlon = interp3d_at_coordinate(altitudeVsPressure{2},latIndex,lonIndex,altitudeVsPressure{1},initial_latitude,initial_longitude);
    temperatureVsPressure_latlon = interp3d_at_coordinate(temperatureVsPressure{2},latIndex,lonIndex,temperatureVsPressure{1},initial_latitude,initial_longitude);
    zWindVsPressure_latlon = interp3d_at_coordinate(zWindVsPressure{2},latIndex,lonIndex,zWindVsPressure{1},initial_latitude,initial_longitude);
    uWindVsPressure_latlon = interp3d_at_coordinate(uWindVsPressure{2},latIndex,lonIndex,uWindVsPressure{1},initial_latitude,initial_longitude);
    vWindVsPressure_latlon = interp3d_at_coordinate(vWindVsPressure{2},latIndex,lonIndex,vWindVsPressure{1},initial_latitude,initial_longitude);

    pressureVsAltitude_latlon = interp1(altitudeVsPressure_latlon,altitudeVsPressure{1},interpAltitude, 'linear', 'extrap')'; % [Pa]
    temperatureVsAltitude = interp1(altitudeVsPressure_latlon,temperatureVsPressure_latlon,interpAltitude, 'linear', 'extrap'); % [K]
    zWindVsAltitude = interp1( ...
        interp1(altitudeVsPressure_latlon,altitudeVsPressure{1},zWindVsPressure{1},'linear','extrap'), ...
        zWindVsPressure_latlon,interpAltitude, 'linear', 'extrap'); % [m/s]
    uWindVsAltitude = interp1( ...
        interp1(altitudeVsPressure_latlon,altitudeVsPressure{1},uWindVsPressure{1},'linear','extrap'), ...
        uWindVsPressure_latlon,interpAltitude, 'linear', 'extrap'); % [m/s]
    vWindVsAltitude = interp1( ...
        interp1(altitudeVsPressure_latlon,altitudeVsPressure{1},vWindVsPressure{1},'linear','extrap'), ...
        vWindVsPressure_latlon,interpAltitude, 'linear', 'extrap'); % [m/s]

    % Compare US standard atmosphere to GFS data for debug purposes
    [T, a, P, rho] = atmoscoesa(interpAltitude);
    figure(1); 
    plot(interpAltitude,P,interpAltitude,pressureVsAltitude_latlon);
    title(sprintf('Pressure (%g, %g)',initial_latitude,initial_longitude));
    xlabel('Altitude'); ylabel('Pa'); 
    legend('COESA',sprintf('GFS %s',initial_time));
    figure(2);
    plot(interpAltitude,T,interpAltitude,temperatureVsAltitude); 
    title(sprintf('Temperature (%g, %g)',initial_latitude,initial_longitude));
    xlabel('Altitude'); ylabel('K');
    legend('COESA',sprintf('GFS %s',initial_time));
else
    % initialize placeholders for lookup tables
    placeholder_index_asc = [1 2];
    placeholder_index_desc = [2 1];
    placeholder_datacube = zeros(2,2,2);
    pressureVsAltitude = placeholder_datacube; % [m]
    temperatureVsPressure = {placeholder_index_desc, placeholder_datacube}; % [K]
    uWindVsPressure = {placeholder_index_desc, placeholder_datacube}; % [m/s]
    vWindVsPressure = {placeholder_index_desc, placeholder_datacube}; % [m/s]
    zWindVsPressure = {placeholder_index_desc, placeholder_datacube}; % [m/s]
    interpAltitude = placeholder_index_asc;
    latIndex = placeholder_index_asc;
    lonIndex = placeholder_index_asc;
end

% Import balloon parameters
addpath(path_to_balloon_library); % import balloon configuration files
balloon_parameters = import_balloon(balloon_name);

% Derive balloon parameters from config
lift_gas = balloon_parameters.spec.lifting_gas;
m_balloon = balloon_parameters.spec.mass.value; % [kg] mass of the balloon
burst_volume = balloon_parameters.spec.volume_burst.value; % [m^3] Mission ends if balloon volume is above this value!
burst_altitude = balloon_parameters.spec.altitude_burst.value; % [m] Mission ends if altitude is above this value! 
release_volume = balloon_parameters.spec.volume_release.value; % [m^3]
M = molar_mass(lift_gas); % [kg/mol] molar mass of lifting gas
Mair = molar_mass('air'); % [kg/mol] molar mass of air
balloon_drag_coeff = balloon_parameters.spec.drag_coefficient; % coefficient of drag

combined_dry_mass = payload_dry_mass+m_balloon;
gas_for_equilibrium_at_target = gas_for_equilibrium(combined_dry_mass, lift_gas, target_altitude) % [kg]
reserved_gas_mass = 0;%gas_for_equilibrium(combined_dry_mass, lift_gas, min_altitude_limit) + gas_reserve_buffer_above_equilibruim % [kg]
recommended_fill_mass = get_recommended_fill_mass(combined_dry_mass+consumable_mass, lift_gas, balloon_parameters.spec.free_lift_recommended.value) % [kg]
requested_gas_budget = extra_gas_above_reserve + reserved_gas_mass
balloon_fill_mass = max([ ...
    gas_for_equilibrium_at_target, ...
    recommended_fill_mass, ...
    requested_gas_budget]) % [kg]

% if reserved_gas_mass > balloon_fill_mass
%     error("reserved gas must be a fraction of balloon fill mass");
% end
% if balloon_fill_mass < calculate_required_gas(combined_dry_mass+consumable_mass, lift_gas, initial_altitude)
%     error("not enough gas to get off the ground!");
% end

% sensor models
BMP388_pressure_variance = 1.2^2; % datasheet accuracy: 1.2 Pa RMS
BMP388_temperature_variance = 1; % datasheet accuracy: 1 degC RMS
BMP388_altitude_variance = 6.9113; % variance of derived altitude over a typical uncontrolled flight
BMP388_sample_rate = 10; % [Hz]
MAXM8_altitude_variance = (2.5*1.7)^2; % datasheet accuracy: 2.5 m RMS horizontal position, assume 1.7x worse for vertical position
MAXM8_velocity_variance = (0.05)^2; % datasheet accuracy: 0.05 m/s RMS
MAXM8_sample_rate = 10; % [Hz]
TAL220_load_variance = 0.001^2; % datasheet accuracy: 0.01 N RMS
TAL220_sample_rate = 10; % [Hz]

% kalman filter settings
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
sysd = c2d(sys,dt); % discrete time
X0 = [initial_altitude, initial_velocity, balloon_fill_mass, consumable_mass]; % initial states
R = diag([BMP388_altitude_variance MAXM8_altitude_variance MAXM8_velocity_variance TAL220_load_variance]); % measurement noise
Q = diag([1e-3; 1e-3; 1; 1]); % process noise
LP_altitude = 24000; % [m] linearization point altitude
LP_velocity = 0; % [m/s] linearization point velocity
LP_mgas = 1.3032; % [kg] linearization point gas mass
LP_mballast = 0; % [kg] linearization point ballast mass
xLP = [LP_altitude; LP_velocity; LP_mgas; LP_mballast]; % linearization state
yLP = C*xLP; % linearization state mapped to sensors

% % LQR settings
% B_bleed = [0;0;1;0];
% B_ballast = [0;0;0;1];
% sys_bleed_discrete = ss(A,B_bleed,C,D,dt)
% sys_ballast_discrete = ss(A,B_ballast,C,D,dt)

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% SIMULATION START %%
% Start the simulation!
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% out = sim('ascent_simulation');