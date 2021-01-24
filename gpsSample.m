function [pos, vel] = gpsSample(truePosition, trueVelocity, gpsObject)
[pos, vel] = gpsObject(truePosition, trueVelocity);
release(gpsObject);
end