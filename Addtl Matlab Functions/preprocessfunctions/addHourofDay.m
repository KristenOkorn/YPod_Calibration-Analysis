function [X,t] = addHourofDay(X, t, ~)
%Gets the time of day from t - NOTE: make sure that "t" is in the
%local time of day when this function is called!

%Get the time of day in hours
Hod = hour(t);

%Append to X
X.HoD = Hod;
end