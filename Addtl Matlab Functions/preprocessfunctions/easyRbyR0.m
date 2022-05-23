function [X,t] = easyRbyR0(X, t, ~)
%Temp in K
%Humidity is relative, not absolute
%Uses minimum value of figaros

%For LA, CA, use humidity = 65
%For CO, use humiditiy = 45

variableNames = X.Properties.VariableNames;
resistanceSensors = {'2600','2602'};%Resistive (MOx) sensors that a voltage divider is used for

%Loop through each sensor and try to find the R0 value to use
for j = 1:length(variableNames)
    
    currentVar = variableNames{j};
    
    %Only do this for resistive sensors (not electrochemical, PID, temperature, etc sensors)
    isSensor = 0;
    for i = 1:length(resistanceSensors)
        if any(regexpi(currentVar,resistanceSensors{i}))
            isSensor = 1;
            break
        end
    end
    if isSensor==0; continue;end
    
    %Get the vector of voltage measurements in millivolts
    tempVolt = table2array(X(:,j)) * (0.188);
    %Assume that this is in a voltage divider with 5V input and a 2kOhm load resistor
    tempR = (5000*2000)./(tempVolt) - 2000;
    
   %Find times that we're at the right temperature
    tgood = abs(X.temperature - 298) < 1;
    
    %Make sure we're also at the right humidity for this time
    hgood = abs(X.humidity - 65) <1;
    
    R0_list = (tempR(tgood));
    Rnew_list= (tempR(hgood)); 
    R_overlap = intersect(R0_list,Rnew_list);
    R0 = min(R_overlap);
    
    
    %If there were no good temperature ranges, allow to continue but don't
    %correct
    if sum(R_overlap)==0
        R0=1;
        warning(['Sensor: ' currentVar ' was not divided by a base resistance (no good temp & humidity overlap found).  This may be caused by temperatures not being in Kelvin']);
    end
    
    %Put R/R0 into the old variable
    X.(currentVar) = tempR./R0;
    
end

end