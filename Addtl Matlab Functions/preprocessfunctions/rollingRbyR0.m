function [X,t] = rollingRbyR0(X, t, ~)
%Need to have the curve fitting toolbox downloaded in order to use
%Temp in K
%Humidity is relative, not absolute
%Uses minimum value of figaros
%Currently set to 1 day - change # of data points for hourly, weekly etc.
%If other MOx sensors are added to pod, add to line 17

%Calculate how many loops we'll need
nloops = width(X);

%Initialize the array to keep track of minutes
mins = size(X,1);
    
for n = 1:nloops %loop through the columns in X
    %Only look for the MOx sensors (Figaros or Ozone)
    if strcmp(X.Properties.VariableNames{n},'Fig2600') == 1 || strcmp(X.Properties.VariableNames{n},'Fig2602') == 1 || strcmp(X.Properties.VariableNames{n},'E2VO3') == 1
        %Initialize the array for the new values
        newvals = [];
        %Get the vector of voltage measurements in millivolts
        tempVolt = table2array(X(:,n)) * (0.188);
        %Assume that this is in a voltage divider with 5V input and a 2kOhm load resistor
        tempR = (5000*2000)./(tempVolt) - 2000;

        %assuming 6 data points per minute, ~8640 data points per day
        for ii = 1:8640:mins-1 
            %if there's more than a day of data points present
            if ii < mins-8640
                win40 = tempR(ii:ii+8640,:); % Find 1 day running window
                
                R0 = min(win40); %get the minimum value

                %Put R/R0 into the old variable
                newVar = win40./R0;
                newVar(8640,:) = [];
                newvals= [newvals; newVar];
        
            %uses this portion if there's less than 1 day of points left
            elseif ii >= mins-8640
                %takes in however many points are remaining
                win40 = tempR(ii:mins-1,:); % Use the remaining data if less than 100 minutes exist after minute (ii)
                
                R0 = min(win40); %get the minimum value
    
                %Put R/R0 into the old variable
                R0=min(win40);
                newVar = win40./R0;
                newVar(length(newVar),:) = [];
                win50=array2table(win40);
                val=win50{end,1};
                newvals= [newvals; newVar; val./R0; val./R0];
            end %if enough data points present
        end %for total # of data points

        %apply smoothing function to prevent "ramping" in the data
        yy = smooth(newvals);
        
        X.(n) = yy; %Replace column with the new values

    end %if a metal oxide sensor
end %for each column of X

    
