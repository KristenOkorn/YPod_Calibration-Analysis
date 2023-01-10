function [rmse] = getRMSE(settingsSet,fittedMdls,rmse,kk)
%% Saves out the rmse for this regression (for linreg only - ANN handles this differently)
                            
if settingsSet.regType == 0 %For linear regression
    tempvar = fittedMdls{:,:,kk}; %initialize temporary variable
    if isa(tempvar,"cell")
        rmse(1,kk) = tempvar{1, 1}.RMSE; %save out for cell (some calibration models only)
    else
        rmse = tempvar.RMSE;
    end
end 