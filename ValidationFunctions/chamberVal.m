function valList = chamberVal(Y, X, t, n)
%Select groups of data from out to in (group 1 gets the first and last x points and group n is the middle)

%% Use last set of data for validation
%Initialize the list of points to default points into the last fold
valList = ones(size(Y,1),1)*2;
t = datenum(t);
t_threshold = datenum(datetime(2018,7,1));
valList(t>t_threshold)=1;


end