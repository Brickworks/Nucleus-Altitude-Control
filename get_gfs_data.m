function [gfsIsobaricDataCubes isobaricIndex latIndex lonIndex, gfsVarIndex] = get_gfs_data(toiDatetimeString, aoiLatLong)
%GET_GFS_DATA Download a Global Forecast System dataset for the time and
% place of interest and returns a dataset indexed by isobaric pressure.
%
%   INPUTS
%   ------
%   toiDatetime     Time of interest in UTC (datetime string)
%   aoiLatLong      Area of interest latitude and longitude (vector
%                   [left, right, top, bottom]
%
%   OUTPUT
%   ------
%   Dataset: GFS 0.25 Degree 
%   Layers:
%       1000 mb
%        975 mb 950 mb 925 mb 900 mb
%        850 mb 800 mb
%        750 mb 700 mb
%        650 mb 600 mb
%        550 mb 500 mb
%        450 mb 400 mb
%        350 mb 300 mb
%        250 mb 200 mb
%        150 mb 100 mb
%         70 mb  50 mb  40 mb  30 mb  20 mb
%         15 mb  10  mb  7 mb   5 mb   3 mb
%       
%   Variables:
%       HGT (geopotential height, meters)
%       UGRD (u-component of wind as ground speed, m/s)
%       VGRD (u-component of wind as ground speed, m/s)
%       TMP (temperature, K)
%       DZDT (vertical wind speed, m/s)
%       RH (relative humidity, %)
%
%   Requires NCTOOLBOX.
%       Download from http://nctoolbox.github.io/nctoolbox/
%       Install by running setup_nctoolbox.m
%
%   Debug downloaded files with NASA Panoply
%       https://www.giss.nasa.gov/tools/panoply/download/

%% download GRiB2 data from GFS
datetime_obj = datetime(toiDatetimeString);
requestUrl = buildGFSQuery(datetime_obj, aoiLatLong);
cacheDir = 'gfs_cache'; % Directory to store GFS data files
cacheFile = sprintf('%s_gfs_0p25.f000', datestr(datetime_obj, 'yyyymmdd-HHMMSS'));
cachePath = fullfile(cacheDir, cacheFile);
websave(cachePath, requestUrl);

%% Parse data
gribtable = table();
grib = ncgeodataset(cachePath);
[gfsIsobaricDataCubes isobaricIndex latIndex lonIndex gfsVarIndex] = splitGeodataset(grib);
end

function requestUrl = buildGFSQuery(toiDatetimeObj, aoiLatLong)
baseUrl = 'https://nomads.ncep.noaa.gov/cgi-bin/';
gfsDataset = 'filter_gfs_0p25.pl';
gfsFile = 'gfs.t00z.pgrb2.0p25.f000';

% get the GFS directory from date and time
% find nearest hour code
hour_codes = [00, 06, 12, 18];
[~,~,idx]=unique(round(abs(hour_codes-toiDatetimeObj.Hour)),'stable');
hour_code=hour_codes(idx==1);
% assemble GFS dataset directory string
date_code_prefix = '%2Fgfs.';
hour_code_prefix = '%2F';
gfsDir = sprintf('%s%04i%02i%02i%s%02i', ...
    date_code_prefix, ...
    toiDatetimeObj.Year, toiDatetimeObj.Month, toiDatetimeObj.Day, ...
    hour_code_prefix, hour_code);

% prepare isobaric layer query
isobar_layers = [1000,975:-25:900,850:-50:100,70,50:-10:20,15:-5:10,7:-2:3];
isobar_query_strings = cell(size(isobar_layers));
for i=1:length(isobar_layers)
    isobar_query_strings(i) = {sprintf('&lev_%g_mb=on', isobar_layers(i))};
end
layers = strjoin(isobar_query_strings,'');

% prepare variables query
var_names = {'HGT', 'UGRD', 'VGRD', 'TMP', 'DZDT', 'RH'};
var_query_strings = cell(size(var_names));
for i=1:length(var_names)
    var_query_strings(i) = {sprintf('&var_%s=on', var_names{i})};
end
vars = strjoin(var_query_strings,'');

% prepare subregion query
subregion = sprintf('&subregion=&leftlon=%g&rightlon=%g&toplat=%g&bottomlat=%g', ...
    aoiLatLong(1), aoiLatLong(2), aoiLatLong(3), aoiLatLong(4));

% assemble query
requestUrl = strcat( ...
    baseUrl, ...
    gfsDataset, ...
    sprintf('?file=%s', gfsFile), ...
    layers, ...
    vars, ...
    subregion, ...
    sprintf('&dir=%s', gfsDir));
end

function cellArray = extractDataFromGrib(grib, var_list)
cellArray = cell(size(var_list));
for i=1:length(var_list)
    var = var_list{i};
    % get table from dataset
    vardata_obj = grib.geovariable(var);
    % extract data from geovar object
    vardata = double(vardata_obj.data(:));
    % eliminate (unused) time dimension
    vardata = squeeze(vardata);
    cellArray{i} = vardata;
end
end

function dataCells = setOf2DmatricesFrom3Dmatrix(matrix, indexAxis)
dataCells = cell(size(matrix,indexAxis),1);
for i=1:size(matrix,indexAxis)
    dataCells{i} = squeeze(matrix(i,:,:));
end
end

function abbrev = getAbbrevFromGeovariable(geovar)
    abbrev = geovar.attribute('abbreviation');
end

function [varDataCubes isobaricIndex latIndex lonIndex varIndex] = splitGeodataset(grib)
gfs_variables = grib.variables;
gfs_axes = grib.geovariable(gfs_variables{1}).axes; % pick any geovariable
% separate axes from data
gfs_variables = setdiff(gfs_variables, gfs_axes);
% ignore time axis
gfs_axes = gfs_axes(~ismember(gfs_axes,'time'));

% extract index arrays from grib
indices = extractDataFromGrib(grib, gfs_axes);
isobaricIndex = indices{1};
latIndex = indices{2};
lonIndex = indices{3};

% extract isobaric x lat x lon data from dataset
varDataCubes = extractDataFromGrib(grib, gfs_variables);

varIndex = cell(size(gfs_variables));
for i=1:length(gfs_variables)
    varIndex{i} = getAbbrevFromGeovariable(grib.geovariable(gfs_variables{i}));
end
end