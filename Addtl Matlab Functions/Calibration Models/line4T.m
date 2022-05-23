function func = line4T(a)
%two sensors (ex. fig 2600 and fig2602), plus temp hum telapsed
%Note: This function assumes that your data has columns named
%"temperature", "humidity", and "telapsed".  It will break if they are not
%in your pod data.

switch a
    case 1; func = @line4TGen;
    case 2; func = @line4TApply;
    case 3; func = @line4TApplyColo;
    case 4; func = @line4TApplyField;
    case 5; func = @line4TReport;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdlobj = line4TGen(Y,X,settingsSet)

columnNames = X.Properties.VariableNames;
foundCol = 0;
mainSensor = settingsSet.podSensors{1}; %Assume that the first sensor is the one to model as the primary sensor
%First column of Y is fitted pollutant
pollutant = Y.Properties.VariableNames{1}; 

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},mainSensor))
        foundCol=foundCol+1; %Keep track of how many columns matching this sensor were found
        mainSensor = columnNames{i}; %Get the real name of the sensor column
    end
end
assert(foundCol == 1,['Could not find a unique column for sensor: ' mainSensor]);

C=[Y(:,pollutant),X(:,mainSensor)]; %Join into a temporary table
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column
C.telapsed = X.telapsed; %Add the elapsed time

%Sensor response as function of gas concentration
%modelSpec = [mainSensor '~' pollutant '+ temperature + humidity + telapsed + temperature:' pollutant];
%Fitted:   mainSensor = 'p(1) + pollutant.*p(2) + p(3)*temperature + p(4)*humidity +p(5)*telapsed + pollutant.*p(6)*T'
%Inverted: pollutant = '(v-p(1) - p(3).*temperature - p(4).*humidity - p(5).*telapsed)/(p(2) + p(6)*temperature)'

%Fit the model
mdl = fitlm(C,'ResponseVar',pollutant);  

mdlobj = {mdl, mainSensor};
end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line4TApply(X,mdlobj,~)

%Get fitted model components
mdl = mdlobj{1};
mainSensor = mdlobj{2};

%Collect the predictor variables
C=X(:,mainSensor); %Main sensor data
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column
C.telapsed = X.telapsed; %Add the elapsed time

%Get the previously fitted coefficients
%coeffs = mdl.Coefficients.Estimate';

%The inverted model is below:
%mdlinv = @(p,sens,temp,hum,telaps) ((sens - p(1) - p(3).*temp - p(4).*hum - p(5).*telaps)./(p(2) + p(6).*temp));

%Predict new concentrations
%y_hat = mdlinv(coeffs,C.(mainSensor),C.temperature,C.humidity,C.telapsed);
y_hat=predict(mdl,C);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 + p2*sensor2 + p3*temp + p4*hum + p5*telapsed";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line4TApplyColo(X,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 + p2*sensor2 + p3*temp + p4*hum + p5*telapsed";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line4TApplyField(X_field,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor1 + p2*sensor2 + p3*temp + p4*hum + p5*telapsed";

end
%% Case 5 - Report out model diagnostics & residuals
%--------------------------------------------------------------------------
function line4TReport(mdl,~)
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
