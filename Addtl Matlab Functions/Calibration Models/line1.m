function func = line1(a)
%One sensor only (no temp hum etc)

switch a
    case 1; func = @line1Gen;
    case 2; func = @line1Apply;
    case 3; func = @line1ApplyColo;
    case 4; func = @line1ApplyField;
end

end

%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdlobj = line1Gen(Y,X,settingsSet)

columnNames = X.Properties.VariableNames;
foundCol = 0;

%Assume that the first sensor is the one to model
mainSensor = settingsSet.podSensors{1}; 

%Assume that the first column of Y is the modeled pollutant
pollutant = Y.Properties.VariableNames{1};

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},mainSensor))
        foundCol=foundCol+1; %Keep track of how many columns matching this sensor were found
        mainSensor = columnNames{i}; %Get the real name of the sensor
    end
end
assert(foundCol == 1,'Could not find a unique sensor column');

C=[Y,X(:,mainSensor)]; %Join into a temporary table

%Fit the model
modelSpec = [pollutant '~' mainSensor]; 
mdl = fitlm(C,modelSpec); 

mdlobj = {mdl, mainSensor};
end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line1Apply(X,mdlobj,~)

%Get fitted model components
mdl = mdlobj{1};
mainSensor = mdlobj{2};

%Predict
y_hat = predict(mdl,X.(mainSensor));

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor";


end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line1ApplyColo(X,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor";
end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line1ApplyField(X_field,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor";

end