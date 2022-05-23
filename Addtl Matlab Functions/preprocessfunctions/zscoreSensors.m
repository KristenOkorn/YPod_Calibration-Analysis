function [X,t] = zscoreSensors(X, t, ~)
% Take the z-score of all the sensor signals except for telapsed

%Calculate how many loops we'll need
nloops = width(X);

for n = 1:nloops %loop through the columns in X
    if strcmp(X.Properties.VariableNames{n},'telapsed') == 0 %don't baseline removed elapsed time column
        %Replace this column variable with its z-score
        X.(n) = zscore(X.(n));
    end
end

