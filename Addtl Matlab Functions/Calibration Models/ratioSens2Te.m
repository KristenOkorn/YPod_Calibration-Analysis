function func = ratioSens2Te(a)
%Fit the sensor response as a function of pollutant, temperature, humidity, and VOC interaction term
%Note: This function assumes that your data has columns named
%"temperature" and "humidity".  It will break if they are not
%in your pod data.

switch a
    case 1; func = @ratioSens2TeGen;
    case 2; func = @ratioSens2TeApply;
    case 3; func = @ratioSens2TeApplyColo;
    case 4; func = @ratioSens2TeApplyField;
    case 5; func = @ratioSens2TeReport;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdlstruct = ratioSens2TeGen(Y,X,settingsSet)

%Assume that the first sensor is the one to model
columnNames = X.Properties.VariableNames;
mainSensor = settingsSet.podSensors{1}; 
extraSensor = settingsSet.podSensors{2}; 
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

foundCol2 = 0;
for j = 1:length(columnNames)
    if any(regexpi(columnNames{j},extraSensor))
        foundCol2=foundCol2+1; %Keep track of how many columns matching this sensor were found
        extrasensorData = X(:,j); %Extract that data into its own table
        extraSensor = columnNames{j}; %Get the real name of the sensor column
    end
end
assert(foundCol2 == 1,['Could not find a unique column for sensor: ' extraSensor]);

%Join data into a temporary table
C=[Y(:,1),sensorData,extrasensorData]; 
%Add the temperature column
C.temperature = X.temperature;
%Add the humidity column
C.humidity = X.humidity; 
%Add the elapsed time column
C.telapsed = X.telapsed;
%Add the sensor interaction term
C.SensInteract = X.Fig2602./X.Fig2600;

%Fit the model
mdl = fitlm(C,'ResponseVar',pollutant);
mdl = compact(mdl);

mdlstruct = {mdl, mainSensor,extraSensor};

end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = ratioSens2TeApply(X,mdlstruct,~)

%Get the column name and model
mdl = mdlstruct{1};
mainSensor = mdlstruct{2};
extraSensor = mdlstruct{3};

C=X(:,{mainSensor,extraSensor}); %Join into a temporary table
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column
C.telapsed = X.telapsed; %Add the elapsed time column
C.SensInteract = C.(extraSensor)./C.(mainSensor); %Add the sensor interaction term

%% Simple way
y_hat = predict(mdl,C);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 (Fig2600) + p2*sensor2 (Fig2602) + p3*temp + p4*hum + p5*SensInteract + p6*telapsed, where SensInteract = Fig2602/Fig2600";

end
%--------------------------------------------------------------------------

%-------%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = ratioSens2TeApplyColo(X,fittedMdl,~)

%Add in the interaction term
X.SensInteract = X.Fig2602./X.Fig2600;

%% Simple way
y_hat = predict(fittedMdl,X);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 (Fig2600) + p2*sensor2 (Fig2602) + p3*temp + p4*hum + p5*SensInteract + p6*telapsed, where SensInteract = Fig2602/Fig2600";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = ratioSens2TeApplyField(X_field,fittedMdl,~)

%Add in the interaction term
X_field.SensInteract = X_field.Fig2602./X_field.Fig2600;

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 (Fig2600) + p2*sensor2 (Fig2602) + p3*temp + p4*hum + p5*SensInteract + p6*telapsed, where SensInteract = Fig2602/Fig2600";

end
%% Case 5 - Report out model diagnostics & residuals-------------------------------------------------------------------
function ratioSens2TeReport(mdl,~)
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
