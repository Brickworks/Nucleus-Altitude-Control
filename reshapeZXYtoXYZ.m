function reshapedMatrix = reshapeZXYtoXYZ(inputMatrix)
%RESHAPELATLONX Reshape 3D array with dimensions ZxNxM to NxMxZ
inputSize = size(inputMatrix);
reshapedMatrix = zeros(inputSize(2),inputSize(3),inputSize(1));
for i=1:length(inputMatrix(:,1,1))
    matrixSlice = squeeze(inputMatrix(i,:,:));
    reshapedMatrix(:,:,i) = matrixSlice;
end
end

