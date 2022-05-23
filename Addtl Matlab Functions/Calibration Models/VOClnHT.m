function func = VOClnHT(a)
%Uses both VOC sensors
%Interaction term of hum & temp 
%Fit the 2 sensors' responses as a function of pollutant, temperature, humidity, and log(temp*hum) interaction term
%Note: This function assumes that your data has columns named
%"temperature" and "humidity". It will break if they are not
%in your pod data.

switch a
    case 1; func = @VOClnHTGen;
    case 2; func = @VOClnHTApply;
    case 3; func = @VOClnHTApplyColo;
    case 4; func = @VOClnHTApplyField;
    case 5; func = @VOClnHTReport;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdlstruct = VOClnHTGen(Y,X,settingsSet)

%Assume that the first sensor is the one to model
columnNames = X.Properties.VariableNames;
mainSensor = settingsSet.podSensors{1}; 
%assumes that the second sensor in the settings set field is the extra one
extraSensor = settingsSet.podSensors{2}; 
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

%Find the column containing the extra sensor for analysis
foundCol2 = 0;
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},extraSensor))
        foundCol2=foundCol2+1; %Keep track of how many columns matching this sensor were found
        extrasensorData = X(:,i); %Extract that data into its own table
        extraSensor = columnNames{i}; %Get the real name of the sensor
        break
    end
end
assert(foundCol2 == 1,['Could not find a unique column for sensor: ' extraSensor]);

%Join data into a temporary table
C=[Y(:,1),sensorData,extrasensorData]; 
%Add the temperature column
C.temperature = X.temperature;
%Add the humidity column
C.humidity = X.humidity; 
%Add the log term
C.ln = log(X.humidity.*X.temperature);

%Fit the model
mdl = fitlm(C,'ResponseVar',pollutant);
mdl = compact(mdl);

mdlstruct = {mdl, mainSensor,extraSensor};

end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = VOClnHTApply(X,mdlstruct,~)

%Get the column name and model
mdl = mdlstruct{1};
mainSensor = mdlstruct{2};
extraSensor = mdlstruct{3};

C=X(:,{mainSensor,extraSensor}); %Join into a temporary table
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column
C.ln = log(C.humidity.*C.temperature);

%% Simple way
y_hat = predict(mdl,C);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 (Fig2600) + p2*sensor2 (Fig2602) + p3*temp + p4*hum + p5*ln, where ln = log(temp*hum)";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = VOClnHTApplyColo(X,fittedMdl,~)

%Add in the interaction term
X.ln = log(X.humidity.*X.temperature);

%% Simple way
y_hat = predict(fittedMdl,X);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 (Fig2600) + p2*sensor2 (Fig2602) + p3*temp + p4*hum + p5*ln, where ln = log(temp*hum)";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = VOClnHTApplyField(X_field,fittedMdl,~)

%Add in the interaction term
X_field.ln = log(X_field.humidity.*X_field.temperature);

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 (Fig2600) + p2*sensor2 (Fig2602) + p3*temp + p4*hum + p5*ln, where ln = log(temp*hum)";

end
%% Case 5 - Report out model diagnostics & residuals
%--------------------------------------------------------------------------
function VOClnHTReport(mdl,~)
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