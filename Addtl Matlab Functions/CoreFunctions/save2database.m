function func = save2database(a)
%saves out data in correct format for Evan's database
switch a
    case 1; func = @save2databaseColo;
    case 2; func = @save2databaseColo2;  
    case 3; func = @save2databaseField;
    case 4; func = @save2databaseSetSet;
end

end

%--------------------------------------------------------------------------
%% Case 1 - Colocation data
%--------------------------------------------------------------------------
function savestruct = save2databaseColo(Y,Y_hatcolo,X,t,currentPod,model,mdlStats,nStats,fittedMdl,settingsSet,eqn)

%Pull location identifiers from the deployLog
rows = height(settingsSet.deployLog); %initialize rows to loop through
for i = 1:rows
    %If this is the current pod & we're looking at the colocation data
    if strcmp(char(settingsSet.deployLog{i,1}),currentPod) == 1 && strcmp(char(settingsSet.deployLog{i,5}),'NA') == 0 && strcmp(char(settingsSet.deployLog{i,5}),'Colocation2') == 0
        %Save out the location identifiers
        identifiers.location = repmat(char(settingsSet.deployLog.Location{i,:}),height(X),1);
        identifiers.latitude = repmat(char(settingsSet.deployLog.Latitude{i,:}),height(X),1);
        identifiers.longitude = repmat(char(settingsSet.deployLog.Longitude{i,:}),height(X),1);
        identifiers.elevation = repelem(settingsSet.deployLog.Elevation(i,:),height(X),1);
        identifiers = struct2table(identifiers);
    end 
end

% Initialize a table to hold the stats
stats = cell2table(cell(height(X),nStats*2));

for i = 1:nStats
    %get the first set of stats
    tempvar=mdlStats{1,1,i};
    %save data to correct column & rename accordingly
    stats.(i+i-1)=repmat(median(tempvar(:,1)),height(X),1); %get cal data
    stats.(i*2)=repmat(median(tempvar(:,2)),height(X),1); %get val data
    stats.Properties.VariableNames{i+1-1} = [settingsSet.statsList{1,i} '_cal_median']; %rename cal
    stats.Properties.VariableNames{i*2} = [settingsSet.statsList{1,i} '_val_median']; %rename val
end

%Combine into 1 file
X.time = t; %add in timestamps
X.estimate = Y_hatcolo; %add in estimates
y=table2array(Y); %get y in matching format
X.reference = y; %add in reference
X.podName = repmat(currentPod,height(X),1);
X.model = repmat(model,height(X),1);
X.project = repmat(settingsSet.deployLog{1,6},height(X),1);
X.dataType = repmat('Colocation',height(X),1);
X.equation = repmat(eqn,height(X),1);
X = horzcat (X,stats);
X = horzcat(X,identifiers);
  
%If linear regression, save out just the coefficients
if settingsSet.regType == 0
    coef = fittedMdl.Coefficients; %save out just the coefficients if linear
    coef = removevars(coef, {'SE','tStat','pValue'}); %delete unnecessary data
    coef=rows2vars(coef); %reformat to keep column & row headings
    coef = removevars(coef, 'OriginalVariableNames'); %delete unnecessary data
    coef = repelem(coef,height(X),1); %repeat for as many rows as X
    %relabel the coefficients
    for i=1:width(coef.Variables)
        coef.Properties.VariableNames{i} = [coef.Properties.VariableNames{i} '_coef'];
    end
    X = horzcat(X,coef); %add the coefficients into X
                                
else %If ANN - pull out weights & biases
    ann.w1=fittedMdl.IW{1,1}; %extract weights
    ann.w2=fittedMdl.LW{2,1}; %extract weights
    ann.b1=fittedMdl.b{1}; %extract biases
    ann.b2=fittedMdl.b{2}; %extract biases
    tempdata = struct2table(ann,'AsArray',1); %Save out the model in a text file
                                
    %Save out ANN weights & biases as separate file
    temppath = [currentPod '_ANN_model.txt']; %name the output file
    temppath = fullfile(settingsSet.outpath,temppath); %Create file path
    save(char(temppath),'tempdata'); %could be .mat also
end
                            
%Save out all colocation data in one file
temppath = [currentPod '_Colocation']; %name the output file
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'X'); %could be .mat also

savestruct = {X};

end

%--------------------------------------------------------------------------
%% Case 2 - Secondary Colocation data
%--------------------------------------------------------------------------
function savestruct = save2databaseColo2(Y,Y_hatcolo,X,t,currentPod,model,mdlStats,nStats,fittedMdl,settingsSet,eqn)

%Pull location identifiers from the deployLog
rows = height(settingsSet.deployLog); %initialize rows to loop through
for i = 1:rows
    %If this is the current pod & we're looking at the colocation data
    if strcmp(char(settingsSet.deployLog{i,1}),currentPod) == 1 && strcmp(char(settingsSet.deployLog{i,5}),'Colocation2') == 1
        %Save out the location identifiers
        identifiers.location = repmat(char(settingsSet.deployLog.Location{i,:}),height(X),1);
        identifiers.latitude = repmat(char(settingsSet.deployLog.Latitude{i,:}),height(X),1);
        identifiers.longitude = repmat(char(settingsSet.deployLog.Longitude{i,:}),height(X),1);
        identifiers.elevation = repelem(settingsSet.deployLog.Elevation(i,:),height(X),1);
        identifiers = struct2table(identifiers);
    end 
end

% Initialize a table to hold the stats
stats = cell2table(cell(height(X),nStats*2));

%Get the stats ready to save out
for i = 1:nStats
    tempvar=mdlStats{1,1,i}; %get each set of stats
    %save data to correct column & rename accordingly
    stats.(i+i-1)=repmat(median(tempvar(:,1)),height(X),1); %get cal data
    stats.(i*2)=repmat(median(tempvar(:,2)),height(X),1); %get val data
    stats.Properties.VariableNames{i+1-1} = [settingsSet.statsList{1,i} '_cal_median']; %rename cal
    stats.Properties.VariableNames{i*2} = [settingsSet.statsList{1,i} '_val_median']; %rename val
end

%Combine into 1 file
X.time = t; %add in timestamps
y=table2array(Y); %get y in matching format
X.Y_ref = y; %add in the "reference" data
X.estimate = Y_hatcolo; %add in the estimate
X.podName = repmat(currentPod,height(X),1); %add in the pod name
X.model = repmat(model,height(X),1); %add in the name of the model used
X.project = repmat(settingsSet.deployLog{1,6},height(X),1); %add in the project name
X.dataType = repmat('Seconday Colocation',height(X),1); %add in the data type
X.equation = repmat(eqn,height(X),1);
X = horzcat(X,identifiers); %add in other info from the deployLog
X = horzcat(X,stats); %add in the statistics
  
%If linear regression, save out just the coefficients
if settingsSet.regType == 0
    coef = fittedMdl.Coefficients; %save out just the coefficients if linear
    coef = removevars(coef, {'SE','tStat','pValue'}); %delete unnecessary data
    coef=rows2vars(coef); %reformat to keep column & row headings
    coef = removevars(coef, 'OriginalVariableNames'); %delete unnecessary data
    coef = repelem(coef,height(X),1); %repeat for as many rows as X
    %relabel the coefficients
    for i=1:width(coef.Variables)
        coef.Properties.VariableNames{i} = [coef.Properties.VariableNames{i} '_coef'];
    end
    X = horzcat(X,coef); %add the coefficients into X
                                
else %If ANN - pull out weights & biases
    ann.w1=fittedMdl.IW{1,1}; %extract weights
    ann.w2=fittedMdl.LW{2,1}; %extract weights
    ann.b1=fittedMdl.b{1}; %extract biases
    ann.b2=fittedMdl.b{2}; %extract biases
    tempdata = struct2table(ann,'AsArray',1); %Save out the model in a text file
                                
    %Save out ANN weights & biases as separate file
    temppath = [currentPod '_ANN_model']; %name the output file
    temppath = fullfile(settingsSet.outpath,temppath); %Create file path
    save(char(temppath),'tempdata'); %could be .mat also
end
                            
%Save out all colocation data in one file
temppath = [currentPod '_Colocation2']; %name the output file
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'X'); %could be .mat also

savestruct = {X};

end

%--------------------------------------------------------------------------
%% Case 3 - Field Data
%--------------------------------------------------------------------------
function savestruct = save2databaseField(X_field,t,Y_hatfield,currentPod,model,fittedMdl,settingsSet,eqn)

%Re-define X
X = X_field;

%Pull location identifiers from the deployLog
rows = height(settingsSet.deployLog); %initialize rows to loop through
for i = 1:rows
    %If this is the current pod & we're looking at the field data
    if strcmp(char(settingsSet.deployLog{i,1}),currentPod) == 1 && strcmp(char(settingsSet.deployLog{i,5}),'NA') == 1
        %Save out the location identifiers
        identifiers.location = repmat(char(settingsSet.deployLog.Location{i,:}),height(X),1);
        identifiers.latitude = repmat(char(settingsSet.deployLog.Latitude{i,:}),height(X),1);
        identifiers.longitude = repmat(char(settingsSet.deployLog.Longitude{i,:}),height(X),1);
        identifiers.elevation = repelem(settingsSet.deployLog.Elevation(i,:),height(X),1);
        identifiers = struct2table(identifiers);
    end 
end

%Combine into 1 file
X.time = t; %add in timestamps
X.estimate = Y_hatfield; %add in estimates
X.podName = repmat(currentPod,height(X),1);
X.model = repmat(model,height(X),1);
X.project = repmat(settingsSet.deployLog{1,6},height(X),1);
X.dataType = repmat('Field',height(X),1);
X.equation = repmat(eqn,height(X),1);
X = horzcat(X,identifiers);

%If linear regression, save out just the coefficients
if settingsSet.regType == 0
    coef = fittedMdl.Coefficients; %save out just the coefficients if linear
    coef = removevars(coef, {'SE','tStat','pValue'}); %delete unnecessary data
    coef=rows2vars(coef); %reformat to keep column & row headings
    coef = removevars(coef, 'OriginalVariableNames'); %delete unnecessary data
    coef = repelem(coef,height(X),1); %repeat for as many rows as X
    %relabel the coefficients
    for i=1:width(coef.Variables)
        coef.Properties.VariableNames{i} = [coef.Properties.VariableNames{i} '_coef'];
    end
    X = horzcat(X,coef); %add the coefficients into X
                                
else %If ANN - pull out weights & biases
    ann.w1=fittedMdl.IW{1,1}; %extract weights
    ann.w2=fittedMdl.LW{2,1}; %extract weights
    ann.b1=fittedMdl.b{1}; %extract biases
    ann.b2=fittedMdl.b{2}; %extract biases
    tempdata = struct2table(ann,'AsArray',1); %Save out the model in a text file
                                
    %Save out ANN weights & biases as separate file
    temppath = [currentPod '_ANN_model']; %name the output file
    temppath = fullfile(settingsSet.outpath,temppath); %Create file path
    save(char(temppath),'tempdata'); %could be .mat also
end
                            
%Save out all field data in one file
temppath = [currentPod '_Field']; %name the output file
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'X'); %could be .mat also

savestruct = {X};

end

%--------------------------------------------------------------------------
%% Case 4 - SettingsSet
%--------------------------------------------------------------------------
function savestruct = save2databaseSetSet(settingsSet)

%Remove or reformat fields to save more conveniently
settingsSet2 = settingsSet; %re-initialize the variable
settingsSet2 = rmfield(settingsSet2,'fileList'); %delete the file list - not useful
settingsSet2.podList = table2cell(settingsSet.podList(:,1)); %save out just the pod names, no other info
settingsSet2.podList = settingsSet2.podList'; %switch rows & columns in podlist
settingsSet2 = rmfield(settingsSet2,'deployLog'); %delete deploy log - already saving this in colocation & field .txt files
settingsSet2 = rmfield(settingsSet2,'loops'); %delete looping variables - not useful

%Save out settingsSet as text file
tempdata=struct2table(settingsSet2,'AsArray',1); %save as an array
temppath = ('SettingsSet'); %name the output file
temppath = fullfile(settingsSet2.outpath,temppath); %Create file path
save(char(temppath),'tempdata'); %could be .mat also

savestruct = {settingsSet};

end