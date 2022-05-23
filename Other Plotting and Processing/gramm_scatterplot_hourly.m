%Scatterplot colored by hour
%1 pod on X axis, another on Y

%Load in the data
load('G7.mat')
load('B2.mat')

%Synchronize & retime to hourly
syn = synchronize(G7,B2);
syn = retime(syn,'hourly');

%create the concentration arrays
x = syn.Y_hatfield_G7;
y = syn.Y_hatfield_B2;

%create the time array (to be used for 'hour')
time = syn.xt;

%group by hour of day
hrs = hour(time); %get the hour 

%add all the data to a structure
newdata = struct;
newdata.x = x;
newdata.y = y;
newdata.hrs = hrs;

%make the boxplot!
clear g
g=gramm('x',newdata.x,'y',newdata.y,'color',newdata.hrs);
g.geom_point();
g.set_names('x','G7','y','B2','color','Hour of Day');
g.set_title('G7 vs. B2 by Time');
figure('Position',[100 100 800 550]);
g.draw();
savefig('G7 B2 Scatter - Hourly.fig');

%have to open & then close figure properties first for these next commands to work
%compatible with general matlab plots, but not gramm specifically
refline(1,0); %add in a 1-1 reference line
xlim([1.8 4.5]) %set x units
ylim([1.8 4.5]) %set y units