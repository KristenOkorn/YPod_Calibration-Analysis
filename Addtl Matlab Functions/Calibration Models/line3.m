function func = line3(a)
%One sensor, temp, hum
%Fit the sensor response as a function of pollutant, temperature, and humidity
%Note: This function assumes that your data has columns named
%"temperature" and "humidity".  It will break if they are not
%in your pod data.

switch a
    case 1; func = @line3Gen;
    case 2; func = @line3Apply;
    case 3; func = @line3ApplyColo;
    case 4; func = @line3ApplyField;
    case 5; func = @line3Report;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdlstruct = line3Gen(Y,X,settingsSet)

columnNames = X.Properties.VariableNames;
foundCol = 0;
mainSensor = settingsSet.podSensors{1}; %Assume that the first sensor is the one to model

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},mainSensor))
        foundCol=foundCol+1; %Keep track of how many columns matching this sensor were found
        sensorData = X(:,i); %Extract that data into its own table
        mainSensor = columnNames{i}; %Get the real name of the sensor
    end
end
assert(foundCol == 1,['Could not find a unique column for sensor: ' mainSensor]);

C=[Y,sensorData]; %Join into a temporary table
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column

%List the reference pollutant as the response variable
responseVar=Y.Properties.VariableNames{1};

%%Fit the model
mdl= fitlm(C,'ResponseVar',responseVar);

mdlstruct = {mdl, mainSensor};

end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line3Apply(X,mdlstruct,~)

%Get the column name and model
mdl = mdlstruct{1};
mainSensor = mdlstruct{2}; 

C=X(:,mainSensor); %Join into a temporary table
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column

coeffs = mdl.Coefficients.Estimate'; %Get the estimates of coefficients

mdlinv = @(p,sens,temp,hum) ((sens-p(1)-p(3).*temp-p(4).*hum)./p(2)); %Invert the model (concentration~Figaro+Temperature+Humidity)

y_hat = mdlinv(coeffs,C.(mainSensor),C.temperature,C.humidity); %Get the estimated concentrations

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*temp + p3*hum";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line3ApplyColo(X,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*temp + p3*hum";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = line3ApplyField(X_field,fittedMdl,~)

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensor + p2*temp + p3*hum";

end
%% Case 5 - Report out model diagnostics & residuals
%--------------------------------------------------------------------------
function line3Report(fittedMdl,~)
try
    fittedMdl.Coefficients.Estimate;
catch 
    disp('Error reporting this model');
end

end
%--------------------------------------------------------------------------
