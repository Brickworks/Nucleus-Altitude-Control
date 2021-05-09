out = sim('ascent_simulation');
runIDs = Simulink.sdi.getAllRunIDs;
runID = runIDs(end);
dataTable = table();
dataTable.time = out.tout;
for i = 1:numElements(out.logsout)
    signal = out.logsout{i}.Values;
    try
        dataTable.(out.logsout{i}.Name) = signal.Data;
    catch
        % do nothing
    end
end
writetable(dataTable,sprintf('saved_runs/run_%i.csv', runID));