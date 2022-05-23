function func = fullLinInt(a)
%This fits a purely linear model using all columns of X as predictors and
%also includes interaction terms between each variable
switch a
    case 1; func = @fullLinInteractGen;
    case 2; func = @fullLinInteractApply;
    case 3; func = @fullLinIntApplyColo;
    case 4; func = @fullLinIntApplyField;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdl = fullLinInteractGen(Y,X,~)

X = table2array(X);
mdl = cell(size(Y,2),1);
for i = 1:size(Y,2)
    y = table2array(Y(:,i));
    
    mdl{i} =fitlm(X,y,'interactions');
end

end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = fullLinInteractApply(X,mdl,~)

X = table2array(X);
y_hat = zeros(size(X,1),length(mdl));
for i = 1:length(mdl)
    y_hat(:,i) = predict(mdl{i},X);
end

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensorcol1 + p2*sensorcol2 + p3*sensorcol1*sensorcol2 + ... for every column from pod";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = fullLinIntApplyColo(X,fittedMdl,~)

%need x as double not table
x=table2array(X);

%% Simple way
y_hat = predict(fittedMdl,x);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensorcol1 + p2*sensorcol2 + p3*sensorcol1*sensorcol2 + ... for every column from pod";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = fullLinIntApplyField(X_field,fittedMdl,~)

%need x as double not table
x_field = table2array(X_field);
%% Simple way
y_hat = predict(fittedMdl,x_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensorcol1 + p2*sensorcol2 + p3*sensorcol1*sensorcol2 + ... for every column from pod";

end
