%change the time to elapsed time
fulldata.time=datenum(fulldata.datetime);
fulldata.telapsed=fulldata.time-fulldata.time(1,1);

%Combine into a new struct
newdata = struct;
newdata.concentrations = fulldata.ch4;
newdata.phase = fulldata.phase;
newdata.time = fulldata.telapsed;

%make the boxplot
clear g

g=gramm('x',newdata.time,'y',newdata.concentrations,'Color',newdata.phase);
g.stat_summary();
g.set_names('x','Time','y','Methane (ppm)','Color','Phase');
%g.facet_grid([],newdata.phase);
g.set_title('Baseline Removed Methane');
figure('Position',[100 100 800 550]);
g.draw();