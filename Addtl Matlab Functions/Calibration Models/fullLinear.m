function func = fullLinear(a)
%This fits a purely linear model using all columns of X as predictors
switch a
    case 1; func = @fullLinearGen;
    case 2; func = @fullLinearApply;
    case 3; func = @fullLinearApplyColo;
    case 4; func = @fullLinearApplyField;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%--------------------------------------------------------------------------
function mdl = fullLinearGen(Y,X,~)

X = table2array(X);
mdl = cell(size(Y,2),1);
for i = 1:size(Y,2)
    y = table2array(Y(:,i));
    
    mdl{i} =fitlm(X,y,'linear');
    
end

end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = fullLinearApply(X,mdl,~)

X = table2array(X);
y_hat = zeros(size(X,1),length(mdl));
for i = 1:length(mdl)
    y_hat(:,i) = predict(mdl{i},X);
end

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensorcol1 + p2*sensorcol2 + ... for every column from pod";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
%--------------------------------------------------------------------------
function [y_hat,eqn] = fullLinearApplyColo(X,fittedMdl,~)

%Need X to be in double format
x=table2array(X);

%% Simple way
y_hat = predict(fittedMdl,x);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensorcol1 + p2*sensorcol2 + ... for every column from pod";

end
%--------------------------------------------------------------------------
%% Case 4 - Apply model to field data
%--------------------------------------------------------------------------
function [y_hat,eqn] = fullLinearApplyField(X_field,fittedMdl,~)

%Need X to be in double format
X_field=table2array(X_field);

%% Simple way
y_hat = predict(fittedMdl,X_field);

%get the equation of this model (used if settingsSet.database = true)
eqn = " intercept + p1*sensorcol1 + p2*sensorcol2 + ... for every column from pod";

end
