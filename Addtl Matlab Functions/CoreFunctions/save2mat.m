function func = save2mat(a)
%Saves the correct data as .mat files depending on the case

switch a
    case 1; func = @save2matModel;
    case 2; func = @save2matFit;
    case 3; func = @save2matPodRef;
    case 4; func = @save2matField;
end

end
%--------------------------------------------------------------------------
%% Case 1 - Save out the info specific to this pod/model combination

function savestruct = save2matModel(Y_hat,fittedMdl,Y_hatcolo,settingsSet,model,currentPod)

%Save the cal/val estimates
disp('---Saving cal/val estimates...');
temppath = [currentPod '_CalVal_Estimates_' model];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path for estimates
save(char(temppath),'Y_hat'); %Save out model estimates
                        
%Save out the fitted model
disp('---Saving the fitted model...');
temppath = [currentPod '_fittedMdl_' model];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'fittedMdl'); %Save out
                        
%Save the full colocation timeseries estimate
disp('---Saving full colocation estimate...');
temppath = [currentPod '_Colocation_Estimate_' model];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path for estimates
save(char(temppath),'Y_hatcolo'); %Save out model estimates

savestruct = {Y_hat};

end

%--------------------------------------------------------------------------
%% Case 2 - Save out the fit data for each pod

function savestruct = save2matFit(Y,X,t,settingsSet,currentPod)

%Save X, Y, and the time to make this reproducible
disp('---Saving out the fit pod data...');               
temppath = [currentPod '_fit_Y_'];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'Y'); %Save out
                
temppath = [currentPod '_fit_X_'];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'X'); %Save out
                
temppath = [currentPod '_fit_t_'];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'t'); %Save out

savestruct = {X};

end

%--------------------------------------------------------------------------
%% Case 3 - Save out the secondary colocation "reference" data

function savestruct = save2matPodRef(xt,Y_ref,settingsSet,model,currentPod)

                
%Save the timestamps to this directory
disp('---Saving full colocation timestamps for Y-ref');
yt = xt;
temppath = [currentPod '_yt_' model];
temppath = fullfile(settingsSet.RefOut,temppath); %Create file path for estimates
save(char(temppath),'yt'); %Save out model estimates
                
%Save out Y-Ref to the new directory
disp('---Saving full colocation estimate as Y-ref');
temppath = [currentPod '_Y_ref_' model];
temppath = fullfile(settingsSet.RefOut,temppath); %Create file path for estimates
save(char(temppath),'Y_ref'); %Save out model estimates

savestruct = {Y_ref};

end

%--------------------------------------------------------------------------
%% Case 4 - Save out the field for each pod

function savestruct = save2matField(Y_hatfield,X_field,xt,settingsSet,fieldModel,currentPod)

%Save the full field estimate
disp('---Saving field estimates...');
temppath = [currentPod '_Field_Estimate_' fieldModel];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path for estimates
save(char(temppath),'Y_hatfield'); %Save out model estimates
        
%Save the preprocessed pod field data
disp('---Saving pod field data...');
temppath = [currentPod '_field_X'];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'X_field'); %Save out

%Save the field timestamps
disp('---Saving field timestamps...');
temppath = [currentPod '_field_t'];
temppath = fullfile(settingsSet.outpath,temppath); %Create file path
save(char(temppath),'xt'); %Save out model estimates

savestruct = {Y_hatfield};

end
