%For all pods at once

%Load in the data
load('B2.mat')
load('B3.mat')
load('B5.mat')
load('C3.mat')
load('G6.mat')
load('G7.mat')

%Retime data to hourly
B2 = retime(B2,'hourly','mean');
B3 = retime(B3,'hourly','mean');
B5 = retime(B5,'hourly','mean');
C3 = retime(C3,'hourly','mean');
G6 = retime(G6,'hourly','mean');
G7 = retime(G7,'hourly','mean');

%create the concentration array
concentration = [B2.Y_hatfield; B3.Y_hatfield; B5.Y_hatfield; C3.Y_hatfield; G6.Y_hatfield; G7.Y_hatfield];

%create the pod array
gB2 = repmat({'B2'},height(B2),1);
gB3 = repmat({'B3'},height(B3),1);
gB5 = repmat({'B5'},height(B5),1);
gC3 = repmat({'C3'},height(C3),1);
gG6 = repmat({'G6'},height(G6),1);
gG7 = repmat({'G7'},height(G7),1);
pod = [gB2; gB3; gB5; gC3; gG6; gG7]; %load g's into array

%Get the datetimes in a number format
B2time=datenum(B2.xt);
B3time=datenum(B3.xt);
B5time=datenum(B5.xt);
C3time=datenum(C3.xt);
G6time=datenum(G6.xt);
G7time=datenum(G7.xt);
times = [B2time; B3time; B5time; C3time; G6time; G7time];

%add all the data to a structure
newdata = struct;
newdata.concentration = concentration;
newdata.pod = pod;
newdata.times = times;

%make the boxplot!
clear g
g=gramm('x',newdata.times,'y',newdata.concentration,'color',newdata.pod);
g.stat_summary();
g.set_names('column','','x','Pod','y','Concentration (ppm)','color','Pod');
%g.facet_grid([],newdata.pod);
g.set_title('Hourly Concentrations');
figure('Position',[100 100 800 550]);
g.draw();