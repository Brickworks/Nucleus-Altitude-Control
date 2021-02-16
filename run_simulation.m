out = sim('ascent_simulation');
lat = out.logsout{31}.Values.Data;
lon = out.logsout{32}.Values.Data;
alt = -out.logsout{13}.Values.Data;

fig = uifigure;
g = geoglobe(fig);
trajectory = geoplot3(g,lat,lon,-alt,'r-','LineWidth',1,'HeightReference','ellipsoid');