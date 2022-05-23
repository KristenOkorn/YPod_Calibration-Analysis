function func = lnH(a)
%Fit the sensor response as a function of pollutant, temperature, humidity, and include log(humidity) interaction term
%Note: This function assumes that your data has columns named
%"temperature" and "humidity".  It will break if they are not
%in your pod data.

switch a
    case 1; func = @lnHGen;
    case 2; func = @lnHApply;
    case 3; func = @lnHApplyColo;
    case 4; func = @lnHApplyField;
    case 5; func = @lnHReport;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdlstruct = lnHGen(Y,X,settingsSet)

%Assume that the first sensor is the one to model
columnNames = X.Properties.VariableNames;
mainSensor = settingsSet.podSensors{1}; 
%assumes that the second sensor in the settings set field is the extra one
%First column of Y is fitted pollutant
pollutant = Y.Properties.VariableNames{1}; 

%Find the column containing the sensor for analysis
foundCol = 0;
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},mainSensor))
        foundCol=foundCol+1; %Keep track of how many columns matching this sensor were found
        sensorData = X(:,i); %Extract that data into its own table
        mainSensor = columnNames{i}; %Get the real name of the sensor
        break
    end
end
assert(foundCol == 1,['Could not find a unique column for sensor: ' mainSensor]);

%Join data into a temporary table
C=[Y(:,1),sensorData]; 
%Add the temperature column
C.temperature = X.temperature;
%Add the humidity column
C.humidity = X.humidity; 
%Add the log term
C.lnH = log(X.humidity);

%Fit the model
mdl = fitlm(C,'ResponseVar',pollutant);
mdl = compact(mdl);

mdlstruct = {mdl, mainSensor};

end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = lnHApply(X,mdlstruct,~)

%Get the column name and model
mdl = mdlstruct{1};
mainSensor = mdlstruct{2};

C=X(:,mainSensor); %Join into a temporary table
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column
C.lnH = log(C.humidity);

%% Simple way
y_hat = predict(mdl,C);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*temp + p3*hum + p4*ln(h)";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = lnHApplyColo(X,fittedMdl,~)

%Add in the interaction term
X.lnH = log(X.humidity);

%% Simple way
y_hat = predict(fittedMdl,X);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*temp + p3*hum + p4*ln(h)";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = lnHApplyField(X_field,fittedMdl,~)

%Add in the interaction term
X_field.lnH = log(X_field.humidity);

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*temp + p3*hum + p4*ln(h)";

end
%% Case 5 - Report out model diagnostics & residuals
%--------------------------------------------------------------------------
function lnHReport(mdl,~)
try
    figure;
    subplot(2,2,1);plotResiduals(mdl);
    subplot(2,2,2);plotDiagnostics(mdl,'cookd');
    subplot(2,2,3);plotResiduals(mdl,'probability');
    subplot(2,2,4);plotResiduals(mdl,'lagged');
    plotSlice(mdl);
catch 
    disp('Error reporting this model');
end

end
%--------------------------------------------------------------------------
