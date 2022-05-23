%Initialize the entire field
%to use variogram function, has to be a square selection
[X,Y] = meshgrid(0:21); %size of your square grid


%Assume each node starts with the background concentration of methane
%Use our pod not located on the landfill for this
Z = 1.8*ones(size(X));

%get the coordinates where our measurements are
x = [2;2;2;16;15];
y = [18;13;4;13;2];

%load in the estimates & retime them to match the # of data points
load('G7.mat')
load('B2.mat')
load('G6.mat')
load('B3.mat')
load('C3.mat')
data = synchronize(G7,B2,G6,B3,C3);
data = retime(data,'hourly','mean');
data = rmmissing(data);

%Initialize a figure
h = figure;

%create separate kriging maps for each instance of estimates
for i = 1:height(data)
    z = [data{i,1}; data{i,2}; data{i,3}; data{i,4};data{i,5}];
    % calculate the sample variogram
    % note maxdist should be n/2 - using n here
    v = variogram([x y],z,'plotit',false,'maxdist',12);
    % and fit a spherical variogram
    [~,~,~,vstruct] = variogramfit(v.distance,v.val,[],[],[],'model','stable');

    % now use the sampled locations in a kriging
    [Zhat,Zvar] = kriging(vstruct,x,y,z,X,Y);
    imagesc(X(1,:),Y(:,1),Zhat,"AlphaData",0.75); 
    axis tight manual % this ensures that getframe() returns a consistent size
    filename = 'KrigingAnimatedMatern.gif';
    %axis image; axis xy
    title('Kriging Predictions Matern');
    colorbar
    caxis([1.5 3])
    
    %get the image behind the plot
    hold on
    I = imread('landfill_real.png'); 
%     J = flip(I, 2);
%     J = imrotate(J,180);
    k = image(xlim,ylim,I); 
    uistack(k,'bottom')

    %Add the date and time
    yourDate = data.xt(i);  % Perhaps a serial date number
    text(0.01,0.01, datestr(yourDate));

    % Capture the plot as an image 
    frame = getframe(h); 
    im = frame2im(frame); 
    [imind,cm] = rgb2ind(im,256); 

    % Write to the GIF File 
    if i == 1 
        imwrite(imind,cm,filename,'gif', 'Loopcount',inf); 
    else 
        imwrite(imind,cm,filename,'gif','WriteMode','append'); 
    end 
end