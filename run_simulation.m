out = sim('ascent_simulation');
t = out.tout;
lat = out.logsout{31}.Values.Data;
lon = out.logsout{32}.Values.Data;
alt = out.logsout{13}.Values.Data;

figpos = [1000 500 800 400];
uif = uifigure("Position",figpos);
ug = uigridlayout(uif,[1,2]);

% topographic map with ground track
p1 = uipanel(ug);
gx = geoaxes(p1,'Basemap','topographic');
gx.MapCenter = [lat(1),lon(1)]; 
trajectory2D = geoplot(gx,lat,lon,'r-','LineWidth',1); hold(gx,"on")
startPoint = geoscatter(gx,lat(1),lon(1),'bo');
endPoint = geoscatter(gx,lat(end),lon(end),'bx');

% globe with 3D trajectory
p2 = uipanel(ug);
gg = geoglobe(p2,'Basemap','satellite');
trajectory3D = geoplot3(gg,lat,lon,alt,'r-','LineWidth',1,'HeightReference','ellipsoid'); hold(gg,"on")

% % hab hub prediction
% flightdata = table2array(readtable('../flight_path_Reno2021-02-22T17-00-00Z.csv'));
% habhub_t = flightdata(:,1)-flightdata(1,1); % convert unix time to delta t
% habhub_lat = flightdata(:,2);
% habhub_lon = flightdata(:,3);
% habhub_alt = flightdata(:,4);
% % topographic map with ground track
% habhubtrajectory2D = geoplot(gx,habhub_lat,habhub_lon,'g-','LineWidth',1); hold(gx,"on");
% startPoint = geoscatter(gx,habhub_lat(1),habhub_lon(1),'ko');
% endPoint = geoscatter(gx,habhub_lat(end),habhub_lon(end),'kx');
% % globe with 3D trajectory
% trajectory3D = geoplot3(gg,habhub_lat,habhub_lon,habhub_alt,'g-','LineWidth',1,'HeightReference','ellipsoid');
% 
% figure(2);
% plot(t,alt,habhub_t,habhub_alt); grid on; legend('Model', 'HabHub');
% xlabel('Time (s)'); ylabel('Altitude (m)');
% figure(3);
% plot(t,out.logsout{33}.Values.Data,habhub_t,10*ones(size(habhub_t)));