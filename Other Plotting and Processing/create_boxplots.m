%get the data by pollutant in order - manually
concentration = [ch4; nmhc];

%create the pollutant array
gCH4=repmat({'Methane'},length(ch4),1);
gNMHC=repmat({'NMHC'},length(nmhc),1);
pollutant = [gCH4; gNMHC];

%create the phase array
phase = data.phase;

%group by hour of day
hour = data.hour;

%add all the data to a structure
newdata = struct;
newdata.concentration = concentration;
newdata.pollutant = pollutant;
newdata.phase = phase;
newdata.hour = hour;

%make the boxplot!
clear g
g=gramm('x',newdata.hour,'y',newdata.concentration,'color',newdata.phase);
g.stat_smooth();
g.set_names('column','','x','Hour of Day','y','Concentration (ppm)','color','Phase');
g.facet_grid([],newdata.pollutant);
g.set_title('Hourly Concentrations');
figure('Position',[100 100 800 550]);
g.draw();