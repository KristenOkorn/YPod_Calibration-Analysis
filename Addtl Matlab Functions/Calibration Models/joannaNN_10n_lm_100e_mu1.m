function func = joannaNN_10n_lm_100e_mu1(a)
%This model creates principal components from X and then fits a linear
%model to it including interaction terms.  NOTE: Data does NOT need to
%already be in PCA form when it is passed to this function

%This is the base model for creating any artificial neural network.
switch a
    case 1; func = @joannaNN_10n_lm_100e_mu1fit;
    case 2; func = @joannaNN_10n_lm_100e_mu1Apply;
    case 3; func = @joannaNN_10n_lm_100e_mu1ApplyColo;
    case 4; func = @joannaNN_10n_lm_100e_mu1ApplyField;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Generate Model
%-----------------------------FIT FUNC-------------------------------------
function mdls = joannaNN_10n_lm_100e_mu1fit(Y,X,~)

%% Use matrix formatting
x = table2array(X)';

%% Grow a neural net for each column of Y
y_hat = zeros(size(Y,2),size(Y,1));
mdls = cell(size(Y,2),1);
for i=1:size(Y,2)
    %% Get current y column
    y_t = table2array(Y(:,i))';
    
    %% Number of hidden layers:
    H = 1;
    %Size of those layers
    n = 10;
    
    % Choose a Training Function
    % For a list of all training functions type: help nntrain
    % 'trainlm' is usually fastest.
    % 'trainbr' takes longer but may be better for challenging problems.
    % 'trainscg' uses less memory. Suitable in low memory situations.
    tfunc = 'trainlm';% Bayesian Regularization backpropagation.
    
    %% Create the net
    %Define the number of hidden layers
    N = ones([1 H]);
    D = n.*N;
    hiddenLayerSize = D;
    
    %Define the  training function
    trainFcn = tfunc;
    
    % Create a Fitting Network
    net = fitnet(hiddenLayerSize,trainFcn);
    
    %% Define training characteristics of the net
    net.trainParam.epochs = 100; %1000 Maximum number of epochs to train
    net.trainParam.goal = .0000000001; %0 Performance goal
    net.trainParam.mu = .001 ; %0.005 Marquardt adjustment parameter
    %net.trainParam.mu_dec  = ;          % 0.1  Decrease factor for mu
    %net.trainParam.mu_inc  = ;           % 10  Increase factor for mu
    %net.trainParam.mu_max   = ;        % 1e10  Maximum value for mu
    net.trainParam.max_fail  = 5;        %   0  Maximum validation failures
    %net.trainParam.min_grad  = ;       % 1e-7  Minimum performance gradient
    %net.trainParam.show   = ;           %  25  Epochs between displays
    %net.trainParam.showCommandLine = ; % false  Generate command-line output
    %net.trainParam.showWindow = true;      % true  Show training GUI
    %net.trainParam.time  = inf ;            % inf  Maximum time to train in seconds
    
    %% Choose Input and Output Pre/Post-Processing Functions
    % For a list of all processing functions type: help nnprocess
    net.input.processFcns = {'removeconstantrows','mapminmax'};
    net.output.processFcns = {'removeconstantrows','mapminmax'};
    
    
    %% Setup Division of Data for Training, Validation, Testing
    % % For a list of all data division functions type: help nndivide
    net.divideFcn = 'divideint';  % "help nndivision" for details
    % net.divideMode = 'sample';  % Divide up every sample
    % net.divideParam.trainRatio = 50/100;
    % net.divideParam.valRatio = 15/100;
    
    %% Choose a Performance Function
    % For a list of all performance functions type: help nnperformance
    net.performFcn = 'sse';  % Mean Squared Error
    
    %% Choose Plot Functions
    % For a list of all plot functions type: help nnplot
    net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
        'plotregression', 'plotfit'};
    %net.trainParam.mu_inc = 1;
    
    %% Train the Network
    [net,~] = train(net,x,y_t);
    
    %% Test the Network
    y_hat(i,:) = net(x);
    
    %% Save the model
    mdls{i} = net;
end
end
%--------------------------------------------------------------------------
%% Case 2 - Apply model to calibration & validation data
%---------------------------Apply------------------------------------------
function [y_hat,eqn] = joannaNN_10n_lm_100e_mu1Apply(X,mdls,~)

x = table2array(X)';

y_hat = zeros(length(mdls),size(X,1));
for i=1:length(mdls)
    net = mdls{i};
    y_hat(i,:) = net(x);
end
y_hat = y_hat';

%get the equation of this model (used if settingsSet.database = true)
eqn = "H=1, n=10, trainingfn=trainlm, epochs=100, goal=.001, mu=.001";

end
%--------------------------------------------------------------------------
%% Case 3 - Apply model to full colocation data
function [y_hat,eqn] = joannaNN_10n_lm_100e_mu1ApplyColo(X,fittedMdl,~)

x = table2array(X)';

y_hat = zeros(length(fittedMdl),size(X,1));
for i=1:length(fittedMdl)
    net = fittedMdl;
    y_hat(i,:) = net(x);
end
y_hat = y_hat';

%get the equation of this model (used if settingsSet.database = true)
eqn = "H=1, n=10, trainingfn=trainlm, epochs=100, goal=.001, mu=.001";

end
%% Case 4 - Apply model to field data
function [y_hat,eqn] = joannaNN_10n_lm_100e_mu1ApplyField(X_field,fittedMdl,~)

x = table2array(X_field)';

y_hat = zeros(length(fittedMdl),size(X_field,1));
for i=1:length(fittedMdl)
    net = fittedMdl;
    y_hat(i,:) = net(x);
end
y_hat = y_hat';

%get the equation of this model (used if settingsSet.database = true)
eqn = "H=1, n=10, trainingfn=trainlm, epochs=100, goal=.001, mu=.001";

end