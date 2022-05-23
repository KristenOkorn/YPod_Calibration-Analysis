%create an array with the data
r2 = [individual_r2; median_r2; univ1_r2; univ2_r2];
rmse = [individual_rmse; median_rmse; univ1_rmse; univ2_rmse];
mbe = [individual_mbe; median_mbe; univ1_mbe; univ2_mbe];
data = [r2; rmse; mbe];

%split by cal method
g_ind=repmat({'Individual'},length(individual_mbe),1);
g_med=repmat({'Median'},length(median_mbe),1);
g_uni1=repmat({'1-Cal'},length(univ1_mbe),1);
g_uni2=repmat({'1-Hop'},length(univ2_mbe),1);
method = [g_ind; g_med; g_uni1; g_uni2; g_ind; g_med; g_uni1; g_uni2; g_ind; g_med; g_uni1; g_uni2];

%split by data type
g_r2=repmat({'R2'},length(r2),1);
g_rmse=repmat({'RMSE'},length(rmse),1);
g_mbe=repmat({'MBE'},length(mbe),1);
type = [g_r2; g_rmse; g_mbe];

%add all the data to a structure
newdata=struct;
newdata.data=data;;
newdata.type=type;
newdata.calmethod=method;

%make the boxplot!
clear g
g=gramm('x',newdata.calmethod,'y',newdata.data,'color',newdata.type);
g.stat_boxplot();
g.set_names('column','','x','Calibration Method');
g.facet_grid([],newdata.type);
g.set_title('New Sensor Calibrations Applied to Old Sensors');
figure('Position',[100 100 800 550]);
g.draw();
