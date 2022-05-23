%load in estimates and reference data for each
%do validation & calibration data separately?

%individual
B2ref=synchronize(B2,ref);
B2ref=rmmissing(B2ref);
t_indiv_b2 = target_statistics(B2ref.y_hat,B2ref.CH4);
B5ref=synchronize(B5,ref);
B5ref=rmmissing(B5ref);
t_indiv_b5 = target_statistics(B5ref.y_hat,B5ref.CH4);

individual_bias = [t_indiv_b2.bias; t_indiv_b5.bias];
individual_crmse = [t_indiv_b2.crmsd; t_indiv_b5.crmsd];

%z-scored individual
B2ref=synchronize(B2,ref);
B2ref=rmmissing(B2ref);
t_zindiv_b2 = target_statistics(B2ref.y_hat,B2ref.CH4);
B5ref=synchronize(B5,ref);
B5ref=rmmissing(B5ref);
t_zindiv_b5 = target_statistics(B5ref.y_hat,B5ref.CH4);

zindividual_bias = [t_zindiv_b2.bias; t_zindiv_b5.bias];
zindividual_crmse = [t_zindiv_b2.crmsd; t_zindiv_b5.crmsd];

%1-cal
B3ref=synchronize(B3,ref);
B3ref=rmmissing(B3ref);
t_univ1_b3 = target_statistics(B3ref.y_hat,B3ref.CH4);
B5ref=synchronize(B5,ref);
B5ref=rmmissing(B5ref);
t_univ1_b5 = target_statistics(B5ref.y_hat,B5ref.CH4);
G6ref=synchronize(G6,ref);
G6ref=rmmissing(G6ref);
t_univ1_g6 = target_statistics(G6ref.y_hat,G6ref.CH4);
G7ref=synchronize(G7,ref);
G7ref=rmmissing(G7ref);
t_univ1_g7 = target_statistics(G7ref.y_hat,G7ref.CH4);

univ1_bias = [t_univ1_b3.bias; t_univ1_b5.bias; t_univ1_g6.bias; t_univ1_g7.bias];
univ1_crmse = [t_univ1_b3.crmsd; t_univ1_b5.crmsd; t_univ1_g6.crmsd; t_univ1_g7.bias];

%1-hop
B3ref=synchronize(B3,ref);
B3ref=rmmissing(B3ref);
t_univ2_b3 = target_statistics(B3ref.y_hat,B3ref.CH4);
B5ref=synchronize(B5,ref);
B5ref=rmmissing(B5ref);
t_univ2_b5 = target_statistics(B5ref.y_hat,B5ref.CH4);
G6ref=synchronize(G6,ref);
G6ref=rmmissing(G6ref);
t_univ2_g6 = target_statistics(G6ref.y_hat,G6ref.CH4);
G7ref=synchronize(G7,ref);
G7ref=rmmissing(G7ref);
t_univ2_g7 = target_statistics(G7ref.y_hat,G7ref.CH4);

univ2_bias = [t_univ2_b3.bias; t_univ2_b5.bias; t_univ2_g6.bias; t_univ2_g7.bias];
univ2_crmse = [t_univ2_b3.crmsd; t_univ2_b5.crmsd; t_univ2_g6.crmsd; t_univ2_g7.crmsd];

%median
B2ref=synchronize(B2,ref);
B2ref=rmmissing(B2ref);
t_median_b2 = target_statistics(B2ref.y_hat,B2ref.CH4);
B5ref=synchronize(B5,ref);
B5ref=rmmissing(B5ref);
t_median_b5 = target_statistics(B5ref.y_hat,B5ref.CH4);

median_bias = [t_median_b2.bias; t_median_b5.bias];
median_crmse = [t_median_b2.crmsd; t_median_b5.crmsd];

%ashley
B5ref=synchronize(B5,ref);
B5ref=rmmissing(B5ref);
t_ashley_b5 = target_statistics(B5ref.y_hat,B5ref.CH4);

ashley_bias = [t_ashley_b5.bias];
ashley_crmse = [t_ashley_b5.crmsd];

%combine all the statistics
bias = [individual_bias; zindividual_bias; univ1_bias; univ2_bias; median_bias; ashley_bias];
crmsd = [individual_crmse; zindividual_crmse; univ1_crmse; univ2_crmse; median_crmse; ashley_crmse];

%split by cal method
g_ind=repmat({'Individual'},length(individual_bias),1);
g_zindiv=repmat({'Z-Individual'},length(zindividual_bias),1);
g_uni1=repmat({'1-Cal'},length(univ1_bias),1);
g_uni2=repmat({'1-Hop'},length(univ2_bias),1);
g_med=repmat({'Median'},length(median_bias),1);
g_ashley=repmat({'Sensor Norm'},length(ashley_bias),1);
method = [g_ind; g_zindiv; g_uni1; g_uni2; g_med; g_ashley];

%add all the data to a structure
newdata=struct;
newdata.crmsd = crmsd;
newdata.bias = bias;
newdata.method=method;

%make the boxplot!
clear g
g=gramm('x',newdata.crmsd,'y',newdata.bias,'color',newdata.method);
g.geom_point;
g.set_names('x','CRMSD','y','MBE');
%g.facet_grid([],newdata.type);
g.stat_ellipse('type','95percentile','geom','area','patch_opts',{'FaceAlpha',0.1,'LineWidth',2});
g.set_title('');
figure('Position',[100 100 800 550]);
g.draw();
