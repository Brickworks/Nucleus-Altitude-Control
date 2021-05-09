# Nucleus-Altitude-Control
Simulink model of the HAB's control logic and flight physics simulation.

1. Tweak simulation parameters and controller settings in `configure_simulation.m`
2. Run `configure_simulation.m`
3. Open `ascent_simulation.slx` in Simulink
4. (Optionally) Open the _Data Inspector_ to view simulation data
5. (Optionally) Run the model and plot in 3D on a globe with `run_simulation.m`

Simulate a flight path using GFS data by setting `use_std_atmo=false`,
otherwise the simulation assumes a COESA 1976 standard atmosphere. If this
setting is true, running `configure_simulation.m` will [query GFS](https://www.nco.ncep.noaa.gov/pmb/products/gfs/)
for weather data close to the specified simulation start time and interpolate
it for use a lookup table when the model runs. The data is stored in a subdir
of the current working directory.

## Dependencies
* MATLAB + Simulink (Designed and tested on R2020a)
* (Optional) MATLAB Mapping Toolbox for plotting flight path on the globe

This tools was created as a design aid and exploration tool to support
the control system design for [Brickworks/mfc_apps](https://github.com/Brickworks/mfc-apps/tree/main/control_apps).

More documentation available upon request!
