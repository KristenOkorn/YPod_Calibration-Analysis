function [X,t] = remove_baseline(X, t,~)
%This uses a 3 hr (180 min) window
%Need to have the curve fitting toolbox downloaded in order to use

%Calculate how many loops we'll need
nloops = width(X);

%Initialize array to keep track of minutes
mins = size(X,1);

for n = 1:nloops %loop through the columns in X
    if strcmp(X.Properties.VariableNames{n},'telapsed') == 0 %don't baseline removed elapsed time column
        %Initialize a baseline variable
        baseline = [];
        % Iterate through each minute (ii), using 180 minute windows from minute (ii) to (ii + 180) to find baseline
        for ii = 1:180:mins-1 
            %if there's more than 100 data points present
            if ii < mins-180
                win40 = X(ii:ii+180,:); % Find 100 minute running window
                %fit the kernel distribution
                [~,xi] = ksdensity(win40.(n)); 
                %find the 25th percentile of the distribution
                desiredp=xi(1,25);
                %replace all those values with the new number
                newX = desiredp.* ones(180,1);
                baseline = [baseline; newX];
        
            %uses this portion if there's less than 180 points left
            elseif ii >= mins-180
                %calculate how many points are left
                remain = mins - ii +1;
                %takes in however many points are remaining
                win40 = X(ii:mins-1,:); % Use the remaining data if less than 100 minutes exist after minute (ii)
                %the rest is all the same
                %fit the kernel distribution
                [~,xi] = ksdensity(win40.(n)); 
                %find the 25th percentile of the distribution
                desiredp=xi(1,25);
                %replace all those values with the new number
                newX = desiredp.* ones(remain,1);
                baseline = [baseline; newX];

            end %loop of how many data points are remaining

        end %loop through minutes

    %apply smoothing function to complete baseline data
    yy = smooth(baseline);

    %replace the old variable with the baseline removed variable
    X.(n)=X.(n) - yy;
    
    end %if current column isn't telapsed
end %for each column of X