function [fittedMdl,model] = getFittedMdl(rmse,fittedMdls,settingsSet,m,k)
%% Extracts the fitted model with the minimum RMSE
 model = settingsSet.modelList{1,m}; %Get the name of the model
                        
 if settingsSet.regType == 0  %For linear regression
     [~,idx_rmse] = min(rmse); %Locate the smallest RMSE
     tempvar = fittedMdls{m,k,idx_rmse}; %Single out the corresponding fitted model
     if isa(tempvar,"cell") %If this saved as a cell array (certain models only)
        fittedMdl = tempvar{1, 1}; %extract
     else
        fittedMdl = tempvar; %otherwise can just extract
     end
                            
 else %for artificial neural network use the first iteration
    tempvar = fittedMdls{m,k,1}; %find
    fittedMdl = tempvar{1,1}; %extract
 end