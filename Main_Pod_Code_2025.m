%% USAGE NOTES
%{
This code is based on Ricardo Piedraheta's Pod_calibration_generation
code, with attemps to make it more readable and more easily modified.
This is optimized for Matlab R2021b,so some unhandled errors may be caused
by the use of different versions.

%}
%% Change Log
%{
Date        Rev       
12/01/2017  Creation V2.1 - JT
07/18/2018  Minor tweaks and addition of new functions V2.2 - JT
09/13/2018  Modified how fitting and prediction with models occurs to improve consistency - JT
06/11/2019  Modified for use as calibration generator only. See separate code for field application V2.3 -KO
10/15/2021  Re-combined cal/val & field codes; Upgrades to validation system; Allows for linreg, ANN, or universal cal V3.1 -KO
12/9/2021   Minor tweaks and addition of new functions V3.2 - KO
5/27/2024   Changed preprocessfn structure & added "field" category to
            settingsset to accomodate baseline shift correction
7/16/2024   Corrections to addtl matlab functions, removed regtype from
            settingsSet
3/26/25     Added mac slashes; debug podSmooth
%}


%% Clear variables and close old figures
clear variables;
close all;

%% ------------=========Settings for analysis=========------------
%% Select which type of calibration you would like to run
%0 - Individual (each pod gets its own unique calibration model)
%1 - Universal: 1-Cal (one model is applied to all pods)
%2 - Universal: 1-Hop (one pod's estimate are used as "reference" data)
%If either universal method: must use "zscoreSensors" in podPreprocess
settingsSet.calMode = 1;

%% For universal calibration, select the pod to calibrate the rest with
settingsSet.uniPod = 'YPODL5';

%% Keep track of which matlab & code versions were used
settingsSet.MatLab = 'R2021b';
settingsSet.codeV = 'V3.2';

%% Change these values to affect what portions of the code is run
settingsSet.loadOldSettings = false;  %Load a settings set structure from an old run
settingsSet.convertOnly = false;  %Stop after converting (unconverted) pod and reference data files into .mat files
settingsSet.applyCal = true;  %Apply calibrations to the pod files in the "field" folder
settingsSet.database = false; %Save out data in database format

%% These affect how datetime data is imported by function "dataExtract"
%Custom datetime formats to use when trying to convert non-standard import datetime strings
settingsSet.datetimestrs = {'M/d/yy H:mm:ss','M/d/yy H:mm','yyyy.MM.dd H.m.s'};
%Custom date formats to use when trying to convert non-standard import date strings
settingsSet.datestrings = {'yyyy.MM.dd','MM-dd-yyyy'};
%Custom time formats to use when trying to convert non-standard time strings
settingsSet.timestrings = {'H.m.s'};

%% These change the smoothing of pod and reference data in function "smoothData"
%Time in minutes to average data by for analysis
settingsSet.timeAvg = 1;
%Smoothing method for pod data - 0=median, 1=mean, 2=linear interpolation, 3=smoothing spline, 4=mode
settingsSet.podSmooth = 0;
%Smoothing method for reference data. Values are the same as above
settingsSet.refSmooth = 0;

%% In these lists of columns to extract, be sure that the data will have headers with one match to each entry.  Note that partial matches will be used (e.g.: a column with "CO2" would be selected if you entered "CO" below)
%Name of columns in reference files to try to extract from the full data file
settingsSet.refGas = {'O3'}; %Only use one at a time

%List of sensor signals to extract from the full pod data file
%Use "allcol" to extract all columns that are not dates
%Light VOC - 'Fig2600', Heavy VOC - 'Fig2602', CO2 - 'CO2', Ozone - 'E2VO3'
%CO with small green board (baseline mocon pin) - 'blMocon'
%CO on larger red board (quadstats) - 'Quad_Main3'
settingsSet.podSensors = {'E2VO3'}; %

%List of environmental sensor signals to extract from the full pod data file
%These are separated from the other sensors in case they need to be treated differently than the other sensors (e.g. when determining interaction terms
settingsSet.envSensors = {'temperature','humidity'}; %

%% For function lists, enter function names in the order in which you'd like them to be performed (if it matters)
%Preprocessing functions for reference data
settingsSet.refPreProcess = {'removeNaNs','remove999','sortbyTime'};%

%Preprocessing functions for pod data
%If universal cal, must use "zscoreSensors"
%If ANN, can add interaction terms here
settingsSet.podPreProcess = {'TempC2K','humidrel2abs','removeNaNs','podTimeZone','podSmooth','zscoreSensors',};%'podSmooth','zscoreSensors' 

%Any extra preprocessing functions just for field pod data
settingsSet.podPreProcessField = {'correctO3drift'}; %'podSmooth'

%Calibration models to fit on pod data
%If individual cal, use as many as you like
%If universal cal, can only use one
settingsSet.modelList = {'rf_plain'};
%settingsSet.modelList = {'joannaNN','joannaNN_lnth','joannaNNinvT','CO2Te','joannaNN_lnht','joannaNN_ln_th_'};
%settingsSet.modelList = {'joannaNN','joannaNN_lnth','joannaNN_ratioSens1','joannaNN_ratioSens2','joannaNN_multiSens','joannaNNinvT','newfractionTe','ratioSens1','ratioSens1Te','ratioSens2','ratioSens2Te','VOClin','VOClnHT'};

%Model to use for field data (if using more than one calibration model)
%This model must have also been called in modelList in order to work
%Only choose one
settingsSet.fieldModel = {'rf_plain'};
%--------------------------------------------------------------------------};

%Validation set selection functions
%settingsSet.valList = {'timeFold','timeofDayVal','temperatureFold','environClusterVal','concentrationsFold'};%
settingsSet.valList = {'randVal'};

%Number of 'folds' for validation (e.g. 5 folds ~ 20% dropped for each validation set)
settingsSet.nFolds = 3;
%Number of folds to actually use (up to nFolds) (will be used in order from 1 to nFolds)
settingsSet.nFoldRep = 3;

%Statistics to calculate
settingsSet.statsList = {'podR2','podRMSE','podMBE'};%'podRMSE','podR2','podCorr'

%Plotting functions run during model fitting loops
settingsSet.plotsList = {'timeseriesPlot'}; %'originalPlot'

%Add to settingsSet to distinguish colo runs from field
%DO NOT EDIT THIS - ALWAYS LEAVE AS NO
settingsSet.field = {'no'};

%Are you on a PC? Edit to 'no' if on a mac
settingsSet.ispc = {'yes'};

%% List of currently implemented functions that can be used in the settings lists above
%***Implemented modeling functions for regression and classification problems
%{
Regression:
-fullLinear - fits Y as a linear function of all columns of X
-fullLinInt - same as fullLinear, but also includes interaction terms
-line1 - fits Y as a linear function only of the first sensor in "podSensors"
-line1T - adds time as an independent predictor and adds an interaction term to allow for changes in sensitivity over time
-line3 - fits the podSensor as a linear function of Y, T, Rh and then inverts the model to predict Y
-line3T - same as line 3, but including an interaction between the temperature and Y
-line4 - fits the podSensor as a linear function of Y, T, Rh, elapsed time, and then inverts the model to predict Y
-line4T - same as line 4, but includes interaction between temperature and Y
-joannaNN - uses all columns and the settings that Joanna developed for using ANN to regress methane concentrations
    *variations of 'joannaNN' use ANN with different interaction
    terms & parameter tuning - see each for details*
    (e.g. joannaNN multiSens includes VOC1*VOC2 interaction term)
-ratioSens1 - typical methane & VOC linear model. interaction term:
    Fig2600/Fig2602 (ratio light:heavy VOCs)
-ratioSens2 - interaction term: Fig2602/Fig2600 (ratio heavy:light VOCs)
-multiSens - interaction term: Fig2600*Fig2602
-new fraction - interaction term: Fig2600/(Fig2600+Fig2602) (ratio light
    VOCs to total VOCs)
%}
%***Preprocessing functions
%{
-addACF - adds columns with a rolling autocorrelation for each variable
-addDerivatives - adds columns for each variable with the time derivative
-addHourofDay - adds another column with the hour as a variable 
-addRollingVar - uses "movvar" to add a rolling variance for each variable
-addSolarAngle - adds a column with solar angle "alpha" (currently using a fixed GPS coordinate)
-addTimeofDay - adds a column "ToD" that ranges from 0 at midnight to 2 at noon in a sine wave-like function
-baseline_remove - removes baseline from data ( only for temp, hum, Fig2600 & Fig2602)
-clusterContin2Categ - uses k-means clustering to convert a matrix of continuous variables to categorical clusters
-easyRbyR0 - divides Figaro values by the minimum value to normalize
-humiditySpikeFilter - removes spikes >2STDs from raw data
-humidrel2abs - converts relative humidity to absolute humidity
-joinPodsData - joins the data from all pods together (this means that looping through each pods is essentially repeating the same analysis multiple times)
-makeCategorical - converts each column to a categorical variable
-makeDiscontTElaps - adds "telapsed" column that ignores gaps longer than "t_gap", which is specified in the function code (currently 5 minutes)
-makePCs - centers and scales each variable and then performs a PCA and allows the user to select the number of PCs to keep. Saves the information necessary to convert new data into the PC space
-makeTElapsed - adds "telapsed" column calculated as t - min(t)
-normalizeMat - center and scale each variable by its standard deviation
-plotWavelets - plots the 2D wavelet power spectrum for each sensor or reference value
-podPMF - normalizes X into principal components
-podSmooth - applies the smoothing method selected by "podSmooth" and "refSmooth" in the settings set
-podTimeZone - adjusts the pod data to match the reference timezone entered above under "settingsSet.refTZ"
-refTimeZone- same as podTimeZone, but this moves reference data to match the pod timezone and allows reference files to be in different timezones
-referenceSpikeFilter - similar filtering to that included in Ricardo's code.  Assigns NaN values to points that differ from the point before or after them by more than 2 std deviations as calculated on a 60 minute rolling window
-refTimeZone - adjusts if the reference is not in the current time zone
-remove999 - removes values exactly equal to -999
-removeDST - adustst the timeseries to remove daylight savings time (allows for data that bridges the time change
-removeNaNs - remove rows that contain NaN values
-removeOOBtemp - removes unrealistic temperature values (assumes values are in K)
-removeSomeZeros - removes 2/3 of points that are exactly 0 to reduce overtraining on synthetic reference data
-removeToDTrends - fits a smooth function to values vs time of day and then removes the fitted diurnal trend
-removeZeros - adds a small, positive value (determined relative to the median) to values that are exactly zero
-rmWarmup - removes 60 minutes after a break in pod data that is longer than 5x the calculated typical interval
-rollingRbyR0_2 - does RbyR0 but over a rolling window to determine min
-rollingRbyR0 - 
-sortbyTime - sorts the data by the timeseries in case it was imported out of order
-TempC2K - adjusts the "temperature" column to convert from celcius to kelvin
-waveletRemove - Not implemented yet, but want to filter data with SSA
-zscoreSensors - used to normalize for universal calibration
%}

%***Validation functions
%{
-chamberVal - Uses last set of data for validation
-clusterVal - Select data groupings with k-means clustering on X data. Note that clusters will not be the same size and that group 1 will be the largest (most points dropped for validation)
-concentrationsFold - Select and drop percentiles of reference concentration starting with the highest levels
-environClusterVal - Select groups of data by clustering on temperature and humidity values
-prepostVal - Select groups of data from out to in (group 1 gets the first and last x points and group n is the middle)
-randHrsVal - Randomly assign hour blocks of data to folds
-randVal - Randomly select data points for validation while trying to maintain roughly the same number of points in each dataset
-temperatureFold - Select and drop percentiles of temperature starting with the lowest temperatures
-timeFold - Split the data into similarly sized folds based on the time from start to end
-timeofDayVal - Split data into quantiles where fold 1 is centered around noon, and the last fold is centered around midnight
%}

%***Plotting functions - for cal/val data only (not field)
%{
-acfPlot - plots the time lagged correlation of Y and podSensor{1} to check that the timestamps are well aligned (max correlation at t_lag=0)
-basicStatsBoxPlots - makes boxplots of variation in model statistics between different "folds" as calculated by "podRMSE", "podR2", and "podCorr" (for now)
-histogramsPlot - plots the distribution of estimated and true concentrations
-hourBoxPlot - creates hourly boxplots of concentrations for the reference and estimated data
-originalPlot - Creates a similar plot to that produced by Ricardo's "camp_plotting" function for each fitted model
-residsTrends - Plots the residuals (y_hat-y) versus each covariate, the timestamp, and the reference concentration
-timeofDayPlot - Plots all reference and estimate values by time of day, colored by the "telapsed" variable (if it exists), or by elapsed time calculated as (t - min(t))
-timeseriesPlot - plots the predictions of each calibration/validation fold as well as the reference data over the same period
-vsRefDens - like "vsReferencePlot", but plots density of estimates to see if there is any weird clumping that's hard to see in a scatter plot
-vsReferencePlot - plots predictions versus the reference data
-XYCorrelations - plots correlations between all variables in X and Y
%}

%***Statistical functions
%{
Regression:
-podCorr - Calculates the Spearman's rho correlation between estimates and reference concentrations
-podRMSE - Calculates the classic RMSE value on the validation and calibration datasets for each fold
-podR2 - Calculates the coefficient of determination (R^2) value on the validation and calibration datasets for each fold
-podMBe - Calculates the mean bias errorr between estimates and reference
-podSkewness - Calculate the "skewness" of the distributions of concentrations for the reference and for the estimates
%}
%-----------------------------------------------------------------
%% ------------=========End settings for analysis=========------------

%% Begin Body of Code
disp('-----------------------------------------------------')
disp('-----------------Pod Analysis Code-------------------')
disp('---------------Begin Code Version 3.2----------------')
disp('-----------------------------------------------------')

%% Perform some Matlab housekeeping, initial checks, and path additions
disp('Performing system checks and housekeeping...')

%Fix for cross compatibility between OSX and Windows, and record which this
%was run on
settingsSet.ispc = ispc;
if settingsSet.ispc; slash = '\'; else; slash = '/'; end

%Add the subfolder containing other functions
addpath(genpath('Addtl Matlab Functions'));

%Check Matlab version installed is recent enough
assert(~verLessThan('matlab','9.1'),'Version of Matlab must be R2016b or newer!');

%Check that requisite toolboxes needed are installed
prod_inf = ver;
assert(any(strcmp(cellstr(char(prod_inf.Name)), 'Statistics and Machine Learning Toolbox')),'Statistics Toolbox Not Installed!');
assert(any(strcmp(cellstr(char(prod_inf.Name)), 'Econometrics Toolbox')),'Econometrics Toolbox Not Installed!');
%assert(~isempty(which('fsolve')),'Function fsolve does not exist!'); % Can also check if specific functions exist like this
clear prod_inf;

%% Allow the user to select an old settings set (this still allows you to select a new folder of data to analyze)
if settingsSet.loadOldSettings
    disp('Select the old settings set...');
    [file,path] = uigetfile('*.mat');
    assert(~isequal(file,0),'"Load Old Settings" was selected, but no file was selected!');
    tempSet = load(fullfile(path,file));
    settingsSet = tempSet.settingsSet;
    clear tempSet file path
end

%% User selects the folder with data for analysis
%Mostly useful for Mac users who don't get GUI labels :(
disp('Select folder with dataset for analysis');

%Prompt user to select folder w/ pod data
settingsSet.analyzeDir=uigetdir(pwd,'Select folder with dataset for analysis');

%Throw an error if user hits "cancel"
assert(~isequal(settingsSet.analyzeDir,0), 'No data folder selected!');
disp(['Analyzing data in folder: ' settingsSet.analyzeDir '...'])

%Make sure z-scoring is on for universal calibration
if settingsSet.calMode == 1 && ~any(strcmp(settingsSet.podPreProcess,'zscoreSensors'))
    warning('For universal calibration, z-scoring of sensors is required. Please add the correct preprocessing function and try again, or press any key to override.')
    pause;
end
%% Review directories for files to analyze
%MODIFY THIS FUNCTION TO ALLOW THE LOADING OF NEW INSTRUMENT TYPES OTHER THAN U-PODS AND Y-PODS
[settingsSet.fileList, settingsSet.podList] = getFilesList(settingsSet.analyzeDir);

%% If universal cal, reorder files so calibrating pod is first
if settingsSet.calMode > 0
    %Find the location of the calibrating pod
    index = find(strcmp(settingsSet.podList,settingsSet.uniPod ));
    %Make sure it isn't already first
    if index ==1
        
    else 
        %Otherwise switch the locations to put it first
        first = settingsSet.podList(1,1);
        uni = settingsSet.podList(1,index);
        settingsSet.podList(1,1) = uni;
        settingsSet.podList(1,index) = first;
        clear first index uni  
    end % if index == 1
    
    else %If not universal cal skip this
  
end

%% Create a folder for outputs to be saved into
settingsSet.outFolder=['Outputs_' datestr(now,'yymmddHHMMSS')]; %Create a unique name for the save folder
disp(['Creating output folder: ' settingsSet.outFolder '...']);
mkdir(settingsSet.analyzeDir, settingsSet.outFolder)
settingsSet.outpath = [settingsSet.analyzeDir,slash,settingsSet.outFolder]; %Store that file path for use later

%% Save out initial settings for reuse
disp('Saving settings structure...');
settingsPath = fullfile(settingsSet.outpath,'run_settings'); %Create file path for settings to save
save(char(settingsPath),'settingsSet'); %Save out settings

%% ------------------------------Read Pod Inventory and Deployment Log------------------------------
%The deployment log is used to determine when a pod was operational and
%what (if any) reference files that data is associated with
disp('Reading deployment log...');
settingsSet.deployLog = readDeployment(settingsSet.analyzeDir);

%The pod inventory is used to assign headers and therefore determine which columns contain required information.
%At a minimum, each pod should have an enrgy with labels 'temperature', 'humidity', 'datetime' or 'Unix time', and then containing the names of sensors entered above
disp('Reading pod inventory...');
settingsSet.podList = readInventory(settingsSet);

%% ------------------------------Convert Data to .mat Files as Needed------------------------------
%Import the Pod Data
disp('Converting unconverted data files to .mat files...');

%Convert pod files to .mat files
convertPodDatatoMat(settingsSet);

%Convert reference files to .mat files
convertRefDatatoMat(settingsSet);

%End the program if user has selected that they only want to convert files
assert(~settingsSet.convertOnly , 'Finished converting files, and "Convert Only" was selected');

%% These are the number of reference files, pods, regressions, validations, and folds to evaluate
nref   = length(settingsSet.fileList.colocation.reference.files.bytes); %Number of reference files
nPods  = size(settingsSet.podList.timezone,1); %Number of unique pods
nModels  = length(settingsSet.modelList); %Number of regression functions
nValidation   = length(settingsSet.valList); %Number of validation functions
nReps = settingsSet.nFoldRep;  %Number of folds to evaluate
nStats = length(settingsSet.statsList); %Number of statistical functions to apply
nPlots = length(settingsSet.plotsList); %Number of plotting functions

fprintf('*** Total number of loops to evaluate: %d *** \n Beginning...\n',nref*nPods*nModels*nValidation*nReps);

%Initialize other functions to be re-used

saveModel = save2mat(1); %for saving out the model & estimates
saveFit = save2mat(2); %for saving out pod data used for fitting
savePodRef = save2mat(3); %for saving out 1-hop "reference" data
saveField = save2mat(4); %for saving out field data

 if settingsSet.database == true
    saveColoData = save2database(1); %for saving colocation data to database
    saveColo2Data = save2database(2); %for saving 2ndary colo data
    saveFieldData = save2database(3); %for saving field data to database
    saveSetData = save2database(4); %for saving out the final settingsSet
 end 

%% --------------------------Fit Calibration Equations--------------------------
%For colocation with reference instrument

   %% --------------------------START POD LOOP------------------------------
    for j = 1:nPods
        %Get current pod name for readability
        currentPod = settingsSet.podList.podName{j};
        
        % For all individual cal & calibrating pod of universal cal
        if settingsSet.calMode == 0 || settingsSet.calMode ~= 0 && strcmp(settingsSet.uniPod,currentPod) == 1
            
            %Keep track of the loop number in case it's needed by a sub function
            settingsSet.loops.j=j;
            fprintf('---Fitting models for pod: %s ...\n',currentPod);
            
            %% Load Pod Data
            fprintf('--Loading data for %s ...\n', currentPod);
            X_pod = loadPodData(settingsSet.fileList.colocation.pods, currentPod);
            %If no data was found for this pod, skip it
            if size(X_pod,1)==1; continue; end
            
            %Extract just columns needed
            disp('--Extracting important variables from pod data');
            [X_pod, xt] = dataExtract(X_pod, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
            
            
            %% --------------------------Pre-Process Pod Data (Filter, normalize, etc)------------------------------
            disp('--Applying selected pod data .......................ing...');
            settingsSet.filtering = 'pod';
            for jj = 1:length(settingsSet.podPreProcess)
                %Keep track of the loop number in case it's needed by a sub function
                settingsSet.loops.jj=jj;
                %Get string representation of function - this must match the name of a regression function
                preprocFunc = settingsSet.podPreProcess{jj};
                fprintf('---Applying pod preprocess function %s ...\n',preprocFunc);
                %Convert this string to a function handle to feed the pod data to
                preprocFunc = str2func(preprocFunc);

                %Apply the filter function
                [X_pod, xt] = preprocFunc(X_pod, xt, currentPod, settingsSet);
                
                %Clear function for next loop
                clear preprocFunc
            end%pod preprocessing loop
            
            %% --------------------------START REFERENCE FILE LOOP------------------------------
            %Note, these reference files will be analyzed independently
            %Only the time and gas concentration will be extracted from each reference file
            %If you want to combine multiple colocations into one calibration, manually append the reference files into a single file
            for i = 1:nref
                
                %Keep track of the loop number in case it's needed by a sub function
                settingsSet.loops.i=i;
                
                %Create empty cell matrices to store fitted models and statistics for each combination
                fittedMdls = cell(nModels,nValidation,nReps);
                mdlStats = cell(nModels,nValidation,nStats);
                Y_hat.cal = cell(nModels,nValidation,nReps);
                Y_hat.val = cell(nModels,nValidation,nReps);
                valList = cell(nValidation,1);
                
                %% ------------------------------Get Reference Data------------------------------
                %Get the reference file to load
                %Indexing is weird if there's only one file
                if nref==1; reffileName = settingsSet.fileList.colocation.reference.files.name;
                else; reffileName = settingsSet.fileList.colocation.reference.files.name{i}; end
                currentRef = split(reffileName,'.');
                currentRef = currentRef{1};
                
                %Load the reference file into memory
                fprintf('-Importing reference file %s ...\n',reffileName);
                Y_ref = loadRefData(settingsSet);
                
                %Extract just the datestring and the gas of interest
                disp('-Extracting important variables from reference data');
                
                [Y_ref, yt] = dataExtract(Y_ref, settingsSet, settingsSet.refGas);
                
                %If this reference file did not contain any of the specified gases, skip the file
                if size(Y_ref,2)==0
                    warning(['No pollutants found in ' reffileName ' continuing onto further reference files...']);
                    clear Y_ref yt
                    continue
                else
                    %Get what pollutant is contained in that reference.  This may behave weirdly if there are multiple pollutants in a reference file
                    fun=@(s)~isempty(regexpi(Y_ref.Properties.VariableNames{1},s, 'once'));
                    if strcmpi(settingsSet.refGas{1},'allcol')
                        settingsSet.fileList.colocation.reference.files.pollutants{i} = 'all';
                    else
                        settingsSet.fileList.colocation.reference.files.pollutants{i} = settingsSet.refGas{cellfun(fun,settingsSet.refGas)};
                    end
                    clear fun
                end
                
                %% --------------------------Pre-process Reference Data (Filter, normalize, etc)--------------------------
                fprintf('-Pre-processing reference file: %s ...\n',reffileName);
                settingsSet.filtering = 'ref';
                for ii = 1:length(settingsSet.refPreProcess)
                    settingsSet.loops.ii=ii;
                    %Get string representation of function - this must match the name of a filter function
                    filtFunc = settingsSet.refPreProcess{ii};
                    fprintf('--Applying reference preprocess function %s ...\n',filtFunc);
                    %Convert this string to a function handle to feed the pod data to
                    filtFunc = str2func(filtFunc);
                    
                    %Save filtered reference data into Y
                    [Y_ref,yt] = filtFunc(Y_ref, yt, settingsSet);
                    
                    %Clear for next loop
                    clear filtFunc
                end%loop for preprocessing reference data
                
                %Match reference and Pod data based on timestamps
                disp('--Joining pod and reference data...');
                [Y, X, t] = alignRefandPod(Y_ref,yt,X_pod,xt,settingsSet);
                
                %Use deployment log to verify that only colocated data is included
                disp('--Checking data against the deployment log...');
                [Y, X, t] = deployLogMatch(Y,X,t,settingsSet,0,0);
                
                %Skip this run if there is no overlap between data and entries in deployment log
                if(isempty(t))
                    warning(['No overlap between data and entries in deployment log for ' reffileName ' and ' currentPod ' this combo will be skipped!']);
                    clear X t Y Y_ref yt
                    continue
                end
                
                %% --------------------------START VALIDATION SETS LOOP------------------------------
                %Create a vector used to separate calibration and validation data sets
                for k = 1:nValidation
                    %Keep track of the loop number in case it's needed by a sub function
                    settingsSet.loops.k=k;
                    %Get string representation of validation selection function
                    validFunc = settingsSet.valList{k};
                    fprintf('----Selecting validation set with function: %s ...\n',validFunc);
                    %Convert this string to a function handle for the validation selection function
                    validFunc = str2func(validFunc);
                    
                    %Run that validation function and get the list of points to fit/validate on for each fold
                    valList{k} = validFunc(Y, X, t, settingsSet.nFolds);
                    %Clear the validation selection function for tidyness
                    clear validFunc
                    
                    %% --------------------------START REGRESSIONS LOOP------------------------------
                    %Fit regression equations and validate them
                    for m = 1:nModels
                        
                        %Keep track of the loop number in case it's needed by a sub function
                        settingsSet.loops.m=m;
                        fprintf('-----Fitting model: %s ...\n',settingsSet.modelList{m});
                        
                        %Get string representation of functions - this must match the name of a function saved in the directory
                        modelFunc = settingsSet.modelList{m}; %Do this for the model function
                        modelFunc = str2func(modelFunc); %Convert this string to a function handle for the regression
                        fitFunc = modelFunc(1); %Get the cal/val prediction function for that regression
                        applyFunc = modelFunc(2); %Get the colocation prediction function for that regression
                        applyColoFunc = modelFunc(3); %Get the field prediction function for that regression
                        clear modelFunc
                        
                        %Get an array ready for comparing RMSE's of models
                        rmse = zeros(1, nReps);
                        %% --------------------------START K-FOLDS LOOP------------------------------
                        
                        %For each repetition (fold) of the validation list, select the data and fit a regression to it
                        for kk = 1:nReps
                            %Keep track of the loop number in case it's needed by a sub function
                            settingsSet.loops.kk=kk;
                            fprintf('------Using calibration/validation fold #%d ...\n',kk);
                            %Check that there is at least one value in the validation list for this fold
                            if ~any(valList{k}==kk)
                                warning('------No entries in validation list for this fold, skipping!')
                                Y_hat.cal{m,k,kk} = NaN;
                                Y_hat.val{m,k,kk} = NaN;
                                fittedMdls{m,k,kk} = NaN;
                                continue
                            end
                            
                            %% Fit the selected regression
                            %Also returns the estimates and fitted model details
                            %Indices for the regression model array are: (m=nRegs,k=nVal,kk=nFolds)
                            disp('-------Fitting model on calibration data...');
                            fittedMdls{m,k,kk} = fitFunc(Y(valList{k}~=kk,:), X(valList{k}~=kk,:), settingsSet);
                            
                            %% Apply the fitted regression to the calibration data
                            disp('-------Applying the model to calibration data...');
                            Y_hat.cal{m,k,kk} = applyFunc(X(valList{k}~=kk,:),fittedMdls{m,k,kk},settingsSet);
                            
                            %% Apply the fitted regression to the validation data
                            disp('-------Applying the model to validation data...');
                            Y_hat.val{m,k,kk} = applyFunc(X(valList{k}==kk,:),fittedMdls{m,k,kk},settingsSet);
                            
                           %% Save out the rmse for this regression
                           [rmse] = getRMSE(settingsSet,fittedMdls,rmse,m,kk); 
          
                        end %loop of calibration/validation folds (kk:nReps)
                        
                        %% Extract the fitted model with the minimum RMSE
                        [fittedMdl,model] = getFittedMdl(rmse,fittedMdls,settingsSet,m,k);
                        
                        %% Apply the fitted regression to the full colocation dataset
                        disp('-------Applying the model to all colocation data...');
                        [Y_hatcolo,eqn] = applyColoFunc(X,fittedMdl,settingsSet);
                        
                        clear calFunc valFunc
                        
                        %% Save out the info specific this pod/model combination
                        saveModel(Y_hat,fittedMdl,Y_hatcolo,settingsSet,model,currentPod);
               
                        %% ------------------------------Determine statistics------------------------------
                        disp('-----Running statistical analyses...');
                        for mm = 1:nStats
                            %Keep track of the loop number in case it's needed by a sub function
                            settingsSet.loops.mm=mm;
                            %Get string representation of function - this must match the name of a function
                            statFunc = settingsSet.statsList{mm};
                            fprintf('------Applying statistical analysis function %s ...\n',statFunc);
                            
                            %Convert this string to a function handle to feed data to
                            statFunc = str2func(statFunc);
                            
                            %Apply the statistical function m=nRegs,k=nVal,mm=nStats
                            mdlStats{m,k,mm} = statFunc(X, Y, Y_hat, valList{k}, fittedMdls(m,k,:), settingsSet);
                            
                            clear statFunc
                        end%loop of common statistics to calculate
                        
                    end%loop of regressions (nModels)
                    
                end%loop of calibration/validation methods (nValidation)
                
                %% ------------------------------Create plots----------------------------------------
                disp('-----Plotting estimates and statistics...');
                for mm = 1:nPlots
                    %Keep track of the loop number in case it's needed by a sub function
                    settingsSet.loops.mm=mm;
                    %Get string representation of function - this must match the name of a function
                    plotFunc = settingsSet.plotsList{mm};
                    fprintf('------Running plotting function %s ...\n',plotFunc);
                    
                    %Convert this string to a function handle to feed data to
                    plotFunc = str2func(plotFunc);
                    
                    %Run the plotting function m=nRegs,k=nVal,kk=nFold
                    plotFunc(t, X, Y, Y_hat,valList,mdlStats,settingsSet);
                    
                    %Save the plots and then close them (reduces memory load and clutter)
                    temppath = [currentPod '_' settingsSet.plotsList{mm}];
                    temppath = fullfile(settingsSet.outpath,temppath);
                    saveas(gcf,temppath,'m');
                    clear temppath
                    close(gcf)
                    clear plotFunc
                end%loop of plotting functions
                
                %% ------------------------------Save fit data for each pod for future reference------------------------------
                saveFit(Y,X,t,settingsSet,currentPod);
                
                 %% ------------------------------Save colocation variables and estimates to database------------------------------

                % If user selected to save data to database
                if settingsSet.database == true && nModels == 1
                    saveColoData(Y,Y_hatcolo,X,t,currentPod,model,mdlStats,nStats,fittedMdl,settingsSet,eqn);
                else
                    warning('Either "save to database was not selected, or more than one model was run. Estimates will not be saved to database on this run!');
                end
                        
                %Clear variables specific to this pod/reference combination
                clear Y X t valList Y_hat fittingStruct
                
                %Clear temporary variables specific to each reference file
                clear Y_ref yt refFileName

                %% For one-hop calibrating pod - get "reference" estimate for colo2
                if settingsSet.calMode == 2 && strcmp(settingsSet.uniPod,currentPod) == 1
                    %Throw a warning if there's no colocation 2 folder
                    temppath=[settingsSet.analyzeDir,slash,'Colocation2'];
                    if not(isfolder(temppath))
                        warning('There was no Colocation2 folder found for one-hop.  Run ended.');
                    end
                    %% Load Pod Data
                    fprintf('--Loading data for %s ...\n', currentPod);
                    X_pod = loadPodData(settingsSet.fileList.colocation2.pods, currentPod);
                    %If no data was found for this pod, skip it
                    if size(X_pod,1)==1; continue; end
                
                    %Extract just columns needed
                    disp('--Extracting important variables from pod data');
                    [X_pod, xt] = dataExtract(X_pod, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
                
                    %% --------------------------Pre-Process Pod Data (Filter, normalize, etc)------------------------------
                    disp('--Applying selected pod data preprocessing...');
                    settingsSet.filtering = 'pod';
                    for jj = 1:length(settingsSet.podPreProcess)
                        %Keep track of the loop number in case it's needed by a sub function
                        settingsSet.loops.jj=jj;
                        %Get string representation of function - this must match the name of a regression function
                        preprocFunc = settingsSet.podPreProcess{jj};
                        fprintf('---Applying pod preprocess function %s ...\n',preprocFunc);
                        %Convert this string to a function handle to feed the pod data to
                        preprocFunc = str2func(preprocFunc);
                    
                        %Apply the filter function
                        [X_pod, xt] = preprocFunc(X_pod, xt, settingsSet);
                    
                        %Clear function for next loop
                        clear preprocFunc
                    end%pod preprocessing loop
                
                    %% Load in the previously fitted model
                    try
                        %Use try/catch in case something didn't save in colocation
                        disp('--Loading data used for fitting...');
                        %Load the data structure
                        location=char(settingsSet.outpath);
                        filename=char([currentPod '_fittedMdl_' settingsSet.modelList{1,1}]);
                        path= [location slash filename];
                        load(path);
                    catch
                        warning(['Problem loading the fitted model from reference: ' currentRef ' and pod: ' currentPod '. This combination will be skipped.']);
                        continue
                    end%Try statement for loading fitted models
                
                    %% Apply the previously fitted model to colocation 2 pod data
                    fprintf('--Applying fitted regression to colocation 2 data--');
                
                    %Get string representation of field function - this must match the name of a function saved in the directory
                    modelFunc = settingsSet.modelList{1,1};
                    %Convert this string to a function handle for the regression
                    modelFunc = str2func(modelFunc);
                    %Get the colocation2 prediction function for that regression
                    applyColoFunc = modelFunc(3);
                    %Clear the main regression function for tidyness
                    clear modelFunc
                
                    %Apply the model to the field data
                    [Y_ref,eqn] = applyColoFunc(X_pod,fittedMdl,settingsSet);
                
                    %% Save the estimates and timestamps as new "reference"
                    % Create a folder for Y-Ref to be saved into
                    disp('Creating secondary reference folder...');
                    settingsSet.RefFolder=['Reference_' datestr(now,'yymmddHHMMSS')]; %Create a unique name for the save folder
                    settingsSet.RefOut = [settingsSet.analyzeDir,slash,'Colocation2',slash,settingsSet.RefFolder]; %Store that file path for use later
                    path = settingsSet.RefOut;
                    mkdir(path); %Make the directory
                    
                    savePodRef(xt,Y_ref,settingsSet,model,currentPod);

                end %if one-hop - colo2 estimate to use as reference
            
            end%loop for each reference file
        
        %Clear temporary variables specific to each pod
        clear X_pod xt currentPod

        %% If one-hop & not the calibrating pod - calibrate the rest
        elseif settingsSet.calMode == 2 && strcmp(settingsSet.uniPod,currentPod) == 0
            
            %Keep track of the loop number in case it's needed by a sub function
            settingsSet.loops.j=j;
            fprintf('---Fitting models for pod: %s ...\n',currentPod);
          
            %% Load Pod Data
            fprintf('--Loading data for %s ...\n', currentPod);
            X_pod = loadPodData(settingsSet.fileList.colocation2.pods, currentPod);
            %If no data was found for this pod, skip it
            if size(X_pod,1)==1; continue; end
            
            %Extract just columns needed
            disp('--Extracting important variables from pod data');
            [X_pod, xt] = dataExtract(X_pod, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
            
            
            %% --------------------------Pre-Process Pod Data (Filter, normalize, etc)------------------------------
            disp('--Applying selected pod data preprocessing...');
            settingsSet.filtering = 'pod';
            for jj = 1:length(settingsSet.podPreProcess)
                %Keep track of the loop number in case it's needed by a sub function
                settingsSet.loops.jj=jj;
                %Get string representation of function - this must match the name of a regression function
                preprocFunc = settingsSet.podPreProcess{jj};
                fprintf('---Applying pod preprocess function %s ...\n',preprocFunc);
                %Convert this string to a function handle to feed the pod data to
                preprocFunc = str2func(preprocFunc);
                
                %Apply the filter function
                [X_pod, xt] = preprocFunc(X_pod, xt, currentPod, settingsSet);
                
                %Clear function for next loop
                clear preprocFunc
            end%pod preprocessing loop
            
            %% --------------------------START "REFERENCE" FILE LOOP------------------------------
            %For 1 hop - should only be the one generated earlier
            %Keep track of the loop number in case it's needed by a sub function
            settingsSet.loops.i=i;
                
            %Create empty cell matrices to store fitted models and statistics for each combination
            fittedMdls = cell(nModels,nValidation,nReps);
            mdlStats = cell(nModels,nValidation,nStats);
            Y_hat.cal = cell(nModels,nValidation,nReps);
            Y_hat.val = cell(nModels,nValidation,nReps);
            valList = cell(nValidation,1);
                
            %% ------------------------------Get Reference Data------------------------------
            %Load the reference files into memory
            fprintf(' ---- Importing previously generated "reference" timestamps ----');
            try
                %Use try/catch in case something didn't save in colocation
                %Load the data structure
                location=char(settingsSet.RefOut);
                filename=char([settingsSet.uniPod '_yt_' settingsSet.modelList{1,1}]);
                %path = [location slash filename];
                path = [location slash filename];
                load(path);
            catch
                warning(['Problem loading the previous estimates from: ' settingsSet.uniPod '. This combination will be skipped.']);
                continue
            end%Try statement for loading data
            
            fprintf(' ---- Importing previously generated "reference" estimates ----');
            try
                %Use try/catch in case something didn't save in colocation
                %Load the data structure
                location=char(settingsSet.RefOut);
                filename=char([settingsSet.uniPod '_Y_ref_' settingsSet.modelList{1,1}]);
                path= [location slash filename];
                load(path);
                %Get "reference" data in a more convenient format
                Y_ref = array2table(Y_ref);
                %Make the pollutant name the title for easy access
                Y_ref.Properties.VariableNames{1} = settingsSet.refGas{1,1};
            catch
                warning(['Problem loading the previous estimates from: ' settingsSet.uniPod '. This combination will be skipped.']);
                continue
            end%Try statement for loading data
           
            %% --------------------------Pre-process Reference Data (Filter, normalize, etc)--------------------------
            fprintf('-Pre-processing reference file: %s ...\n',reffileName);
            settingsSet.filtering = 'ref'; %even though it's really pre-calibrated pod data
            for ii = 1:length(settingsSet.refPreProcess)
                settingsSet.loops.ii=ii;
                %Get string representation of function - this must match the name of a filter function
                filtFunc = settingsSet.refPreProcess{ii};
                fprintf('--Applying reference preprocess function %s ...\n',filtFunc);
                %Convert this string to a function handle to feed the pod data to
                filtFunc = str2func(filtFunc);
                    
                %Save filtered reference data into Y
                [Y_ref,yt] = filtFunc(Y_ref, yt, settingsSet);
                    
                %Clear for next loop
                clear filtFunc
             end%loop for preprocessing reference data
                
             %% Match "reference" and Pod data based on timestamps
             disp('--Joining pod and reference data...');
             [Y, X, t] = alignRefandPod(Y_ref,yt,X_pod,xt,settingsSet);
                
             %Use deployment log to verify that only colocation 2 data is included
             %NOTE: xt is passed to deployLogMatch where "Y" would normally be passed because there is no true reference data
             disp('--Checking data against the deployment log...');
             %the 0 is for field, the 1 is for colo2
             [~, X, t] = deployLogMatch(Y,X,t,settingsSet,0,1);
             %[~, X, t] = deployLogMatch(xt,X,t,settingsSet,0,1);
            
             %Skip this run if there is no overlap between data and entries in deployment log
             if(isempty(t))
                warning(['No overlap between data and entries in deployment log for ' reffileName ' and ' currentPod ' this combo will be skipped!']);
                clear X t Y Y_ref yt
                continue
             end
                
             %% --------------------------START VALIDATION SETS LOOP------------------------------
             %Create a vector used to separate calibration and validation data sets
             for k = 1:nValidation
                %Keep track of the loop number in case it's needed by a sub function
                settingsSet.loops.k=k;
                %Get string representation of validation selection function
                validFunc = settingsSet.valList{k};
                fprintf('----Selecting validation set with function: %s ...\n',validFunc);
                %Convert this string to a function handle for the validation selection function
                validFunc = str2func(validFunc);
                    
                %Run that validation function and get the list of points to fit/validate on for each fold
                valList{k} = validFunc(Y, X, t, settingsSet.nFolds);
                %Clear the validation selection function for tidyness
                clear validFunc
                    
                %% --------------------------START REGRESSIONS LOOP------------------------------
                %Fit regression equations and validate them
                for m = 1:nModels
                        
                    %Keep track of the loop number in case it's needed by a sub function
                    settingsSet.loops.m=m;
                    fprintf('-----Fitting model: %s ...\n',settingsSet.modelList{m});
                        
                    %Get string representation of functions - this must match the name of a function saved in the directory
                    modelFunc = settingsSet.modelList{m};
                    %Convert this string to a function handle for the regression
                    modelFunc = str2func(modelFunc);
                    %Get the generation function for that regression
                    %Note that the function must be set up correctly - see existing regression functions for an example
                    fitFunc = modelFunc(1);
                    %Get the cal/val prediction function for that regression
                    applyFunc = modelFunc(2);
                    %Get the colocation prediction function for that regression
                    applyColoFunc = modelFunc(3);
                    %Get the field prediction function for that regression
                    clear modelFunc
                        
                    %Get an array ready for comparing RMSE's of models
                    rmse = zeros(1, nReps);
                    %% --------------------------START K-FOLDS LOOP------------------------------
                        
                    %For each repetition (fold) of the validation list, select the data and fit a regression to it
                    for kk = 1:nReps
                        %Keep track of the loop number in case it's needed by a sub function
                        settingsSet.loops.kk=kk;
                        fprintf('------Using calibration/validation fold #%d ...\n',kk);
                        %Check that there is at least one value in the validation list for this fold
                        if ~any(valList{k}==kk)
                            warning('------No entries in validation list for this fold, skipping!')
                            Y_hat.cal{m,k,kk} = NaN;
                            Y_hat.val{m,k,kk} = NaN;
                            fittedMdls{m,k,kk} = NaN;
                            continue
                        end
                            
                        %% Fit the selected regression
                        %Also returns the estimates and fitted model details
                        %Indices for the regression model array are: (m=nRegs,k=nVal,kk=nFolds)
                        disp('-------Fitting model on calibration data...');
                        fittedMdls{m,k,kk} = fitFunc(Y(valList{k}~=kk,:), X(valList{k}~=kk,:), settingsSet);
                            
                        %% Apply the fitted regression to the calibration data
                        disp('-------Applying the model to calibration data...');
                        Y_hat.cal{m,k,kk} = applyFunc(X(valList{k}~=kk,:),fittedMdls{m,k,kk},settingsSet);
                            
                        %% Apply the fitted regression to the validation data
                        disp('-------Applying the model to validation data...');
                        Y_hat.val{m,k,kk} = applyFunc(X(valList{k}==kk,:),fittedMdls{m,k,kk},settingsSet);
                            
                        %% Save out the rmse for this regression
                        [rmse] = getRMSE(settingsSet,fittedMdls,rmse,kk);
                            
                    end %loop of calibration/validation folds (nReps)
                        
                    %% Extract the fitted model with the minimum RMSE
                    [fittedMdl,model] = getFittedMdl(rmse,fittedMdls,settingsSet,m,k);
                        
                    %% Apply the fitted regression to the secondary colocation dataset
                    disp('-------Applying the model to all colocation data...');
                    [Y_hatcolo,eqn] = applyColoFunc(X,fittedMdl,settingsSet);
                        
                    clear calFunc valFunc
                        
                    %% Save out the info specific this pod/model combination
                    saveModel(Y_hat,fittedMdl,Y_hatcolo,settingsSet,model,currentPod);
                        
                    %% ------------------------------Determine statistics------------------------------
                    disp('-----Running statistical analyses...');
                    for mm = 1:nStats
                        %Keep track of the loop number in case it's needed by a sub function
                        settingsSet.loops.mm=mm;
                        %Get string representation of function - this must match the name of a function
                        statFunc = settingsSet.statsList{mm};
                        fprintf('------Applying statistical analysis function %s ...\n',statFunc);
                            
                        %Convert this string to a function handle to feed data to
                        statFunc = str2func(statFunc);
                            
                        %Apply the statistical function m=nRegs,k=nVal,mm=nStats
                        mdlStats{m,k,mm} = statFunc(X, Y, Y_hat, valList{k}, fittedMdls(m,k,:), settingsSet);
                            
                        clear statFunc
                    end%loop of common statistics to calculate
                        
                end%loop of regressions (nModels)
                    
             end%loop of calibration/validation methods (nValidation)
                
             %% ------------------------------Create plots----------------------------------------
             disp('-----Plotting estimates and statistics...');
             for mm = 1:nPlots
                %Keep track of the loop number in case it's needed by a sub function
                settingsSet.loops.mm=mm;
                %Get string representation of function - this must match the name of a function
                plotFunc = settingsSet.plotsList{mm};
                fprintf('------Running plotting function %s ...\n',plotFunc);
                    
                %Convert this string to a function handle to feed data to
                plotFunc = str2func(plotFunc);
                    
                %Run the plotting function m=nRegs,k=nVal,kk=nFold
                plotFunc(t, X, Y, Y_hat,valList,mdlStats,settingsSet);
                    
                %Save the plots and then close them (reduces memory load and clutter)
                temppath = [currentPod '_' settingsSet.plotsList{mm}];
                temppath = fullfile(settingsSet.outpath,temppath);
                saveas(gcf,temppath,'m');
                clear temppath
                close(gcf)
                clear plotFunc
             end%loop of plotting functions
                
             %% ------------------------------Save fit data for each pod for future reference------------------------------
            saveFit(Y,X,t,settingsSet,currentPod);

             % If user selected to save data to database
             if settingsSet.database == true && nModels == 1
                saveColo2Data(Y,Y_hatcolo,X,t,currentPod,model,mdlStats,nStats,fittedMdl,settingsSet,eqn);
             else
                warning('Either "save to database was not selected, or more than one model was run. Estimates will not be saved to database on this run!');
             end
                
             %Clear variables specific to this pod/reference combination
             clear Y X t valList Y_hat fittingStruct
                
             %Clear temporary variables specific to each reference file
             clear Y_ref yt refFileName
        
        %Clear temporary variables specific to each pod
        clear X_pod xt currentPod X 
        
        end %if individual or calibrating pod
        
   end%loop for each pod
    
%% Save out final settings structure for future replication/application
disp('Saving settings structure...');
save(char(settingsPath),'settingsSet'); %Save out settings

%% If user selected to save out data to database
if settingsSet.database == true
    saveSetData(settingsSet);
else
    warning('Either "save to database was not selected, or more than one model was run. Estimates will not be saved to database on this run!');
end

%% ~~~~~~~~~~~~~~~~~~~~~~~~~ Field Data ~~~~~~~~~~~~~~~~~~~~~~~~~ 
%This portion of code is only executed if "applyCal" was selected AND there are files in the "field" folder
if ~settingsSet.applyCal || size(settingsSet.fileList.field.pods.files,1)<1
    warning('Either applyCal was not selected, or there is no data in the "Field" folder to apply models to.  Run ended.');
else
%Get a list of unique pods in the new analysis folder
newPodList = settingsSet.podList;
%% ------------------------------Apply models fitted to each pod used in the original calibration------------------------------
for j = 1:nPods
    settingsSet.loops.j=j;
    currentPod = settingsSet.podList.podName{j};
        
    %% Check if this pod is in the new folder before continuing
    if ~any(strcmpi(settingsSet.podList.podName{j},newPodList.podName))
        %If this pod is not in the new folder, skip it
        warning(['Pod: ' settingsSet.podList.podName{j} ' was used in the original calibration but has no field data, so it was skipped.']);
        continue
    end
        
    %% Load pod data
    fprintf('--Loading data for %s ...\n', currentPod);
    X_field = loadPodData(settingsSet.fileList.field.pods, currentPod);
        
    %If no data was found for this pod in the "field" folder, skip it
    if size(X_field,1)==1; continue; end
        
    %Extract just columns needed
    disp('--Extracting important variables from pod data');
    [X_field, xt] = dataExtract(X_field, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
        
   
    %% --------Uses the same preprocessing functions as were used in the original calibration--------
    disp('--Applying selected pod data preprocessing...');
    settingsSet.filtering = 'pod';
    %Add a variable here to prevent cal-only pre-process fns
    settingsSet.field = {'yes'};
    for jj = 1:length(settingsSet.podPreProcess)
        %Keep track of the loop number in case it's needed by a sub function
        settingsSet.loops.jj=jj;
        %Get string representation of function - this must match the name of a regression function
        preprocFunc = settingsSet.podPreProcess{jj};
        fprintf('---Applying pod preprocess function %s ...\n',preprocFunc);
        %Convert this string to a function handle to feed the pod data to
        preprocFunc = str2func(preprocFunc);
            
        %Apply the filter function
        [X_field, xt] = preprocFunc(X_field, xt, currentPod, settingsSet);
            
        %Clear function for next loop
        clear filterFunc
    end%pod preprocessing loop

    %% --------Now add any pre-processing specific to field data--------
    disp('--Applying selected pod data preprocessing...');
    settingsSet.filtering = 'pod';
    for jj = 1:length(settingsSet.podPreProcessField)
        %Keep track of the loop number in case it's needed by a sub function
        settingsSet.loops.jj=jj;
        %Get string representation of function - this must match the name of a regression function
        preprocFunc = settingsSet.podPreProcessField{jj};
        fprintf('---Applying pod preprocess function %s ...\n',preprocFunc);
        %Convert this string to a function handle to feed the pod data to
        preprocFunc = str2func(preprocFunc);
            
        %Apply the filter function
        [X_field, xt] = preprocFunc(X_field, xt, currentPod, settingsSet);
            
        %Clear function for next loop
        clear filterFunc
    end%pod preprocessing loop
        
    %Use deployment log to verify that only field data is included.
    %NOTE: xt is passed to deployLogMatch where "Y" would normally be passed because there is no reference data
    disp('--Checking data against the deployment log...');
    [~, X_field, xt] = deployLogMatch(xt,X_field,xt,settingsSet,1,0);
        
    %Skip this pod/reference if there is no overlap between data and entries in deployment log
    if(isempty(xt))
        warning(['No matching entries in deployment log for these dates for a field deployment of pod: ' currentPod '. This pod will be skipped!']);
        continue
    end
        
    %% ------------------------------Each reference file that was used for calibration------------------------------
    for i = 1:nref
        settingsSet.loops.i=i;
        %Get the name of the reference file
        if nref==1; reffileName = settingsSet.fileList.colocation.reference.files.name;
        else; reffileName = settingsSet.fileList.colocation.reference.files.name{i}; end
        currentRef = split(reffileName,'.'); currentRef = currentRef{1};
            
        %% Load information from the original calibration
        
        %Find the same pod if individual calibration or 1-hop
        if settingsSet.calMode ~= 1
        
            try
                %Use try/catch in case something didn't save in colocation
                disp('--Loading data used for fitting...');
                %Load the data structure
                location=char(settingsSet.outpath);
                filename=char([currentPod '_fittedMdl_' settingsSet.fieldModel{1,1}]);
                path= [location slash filename];
                load(path);
            catch
                warning(['Problem loading the fitted models and estimates from reference: ' currentRef ' and pod: ' currentPod '. This combination will be skipped.']);
                continue
            end%Try statement for loading fitted models
            
        else %otherwise it's one-cal - looking for uniPod fittedMdl
            try
                %Use try/catch in case something didn't save in colocation
                disp('--Loading data used for fitting...');
                %Load the data structure
                location=char(settingsSet.outpath);
                filename=char([settingsSet.uniPod '_fittedMdl_' settingsSet.fieldModel{1,1}]);
                path= [location slash filename];
                load(path);
            catch
                warning(['Problem loading the fitted models and estimates from reference: ' currentRef ' and pod: ' currentPod '. This combination will be skipped.']);
                continue
            end%Try statement for loading fitted models
        
        end %if statement of individual or universal cal
        
  %% Applying model to field data
  fprintf('--Applying fitted regression to field data--');
  
  %Get string representation of field function - this must match the name of a function saved in the directory
  FieldFunc = settingsSet.fieldModel{1,1};
  %Convert this string to a function handle for the regression
  FieldFunc = str2func(FieldFunc);
  %Get the field prediction function for that regression
  applyFieldFunc = FieldFunc(4);
  %Clear the main regression function for tidyness
  clear modelFunc
  
  %Apply the model to the field data
  [Y_hatfield,eqn] = applyFieldFunc(X_field,fittedMdl,settingsSet);
  
  %Get the field model name to save out
  fieldModel = settingsSet.fieldModel{1,1};
              
%% ------------------------------Save info for each pod for future reference------------------------------
   saveField(Y_hatfield,X_field,xt,settingsSet,fieldModel,currentPod);
       
   if settingsSet.database == true && nModels == 1 
       saveFieldData(X_field,xt,Y_hatfield,currentPod,model,fittedMdl,settingsSet,eqn);
   else
        warning('Either "save to database was not selected, or more than one model was run. Estimates will not be saved to database on this run!');
   end        
        %Clear out the field variables
        clear Y_hatfield fieldStruct_X fieldStruct_t 
     end%loop of reference files
    clear X_field xt
     
end%loop of pods

% If user selected to save data to database
   if settingsSet.database == true && nModels == 1
       clear
       pod_data_to_DB_v2
   else
        warning('Either "save to database was not selected, or more than one model was run. Estimates will not be saved to database on this run!');
   end

disp('-------Field application complete. Have fun plotting!-------');
end %applyCal for field data application