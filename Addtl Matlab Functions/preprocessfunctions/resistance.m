function [X,t] = resistance(X, t, ~)
%Converts raw metal oxide sensor signals from voltage (mV) to resistance
%(mili-ohms)

%Temp in K
%Humidity is relative, not absolute
%Uses minimum value of figaros

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

    %Put R/R0 into the old variable
    X.(currentVar) = tempR;
    
end

end