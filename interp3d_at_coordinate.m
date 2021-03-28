function vector = interp3d_at_coordinate(dataCube3d, xIndex, yIndex, zIndex, xSample, ySample)
vector = nan(size(zIndex));
for i=1:length(zIndex)
    vector(i) = interp2(yIndex,xIndex,squeeze(dataCube3d(i,:,:)),ySample,xSample);
end
end