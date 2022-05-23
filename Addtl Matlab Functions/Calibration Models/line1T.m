function func = line1T(a)
%Linear combination of one sensor and the elapsed time
switch a
    case 1; func = @line1TGen;
    case 2; func = @line1TApply;
    case 3; func = @line1TApplyColo;
    case 4; func = @line1TApplyField;
    case 5; func = @line1TReport;

end

end

%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdl  = line1TGen(Y,X,settingsSet)

columnNames = X.Properties.VariableNames;
foundCol = 0;
mainSensor = settingsSet.podSensors{1}; %Assume that the first sensor is the one to model
pollutant = Y.Properties.VariableNames{1};

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},mainSensor))
        foundCol=foundCol+1; %Keep track of how many columns matching this sensor were found
        mainSensor = columnNames{i}; %Get the real name of the sensor
    end
end
assert(foundCol == 1,'Could not find a unique sensor column');

%Join into a temporary table
C=[Y,X(:,mainSensor)]; 
C.telapsed = X.telapsed;

%Sensor response as function of gas concentration and time elapsed
%modelSpec = [mainSensor '~' pollutant ' + telapsed'];
%Fitted:   mainSensor = 'p(1) + pollutant.*p(2) + p(3)*telapsed
%Inverted: pollutant = (mainSensor - p(1) - p(3).*telapsed)./(p(2))

%Fit the model
mdl = fitlm(C,'ResponseVar',pollutant);  

end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line1TApply(X,mdl,settingsSet)

mainSensor = settingsSet.podSensors{1};
columnNames = X.Properties.VariableNames;
foundCol = 0;

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},mainSensor))
        foundCol=foundCol+1; %Keep track of how many columns matching this sensor were found
        mainSensor = columnNames{i}; %Get the real name of the sensor
    end
end
assert(foundCol == 1,'Could not find a unique sensor column');

%Get the data together
C = X(:,mainSensor);
C.telapsed = X.telapsed;

%Get the fitted estimates of coefficients
%coeffs = mdl.Coefficients.Estimate'; 

%Invert the model (concentration~sensor+time)
%mdlinv = @(p,sens,telaps) ((sens - p(1) - p(3).*telaps)./(p(2)));

%Get the estimated concentrations
%y_hat = mdlinv(coeffs,C.(mainSensor),C.telapsed); 
y_hat=predict(mdl,C);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*telapsed";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line1TApplyColo(X,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*telapsed";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line1TApplyField(X_field,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*telapsed";

end

%% Case 5 - Report out model diagnostics & residuals
%--------------------------------------------------------------------------
function line1TReport(mdl,~)
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