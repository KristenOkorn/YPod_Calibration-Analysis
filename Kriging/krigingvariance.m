%Initialize the entire field
[X,Y] = meshgrid(0:12);

%Assume each node starts with the background concentration
Z = 1.8*ones(size(X));

%get the coordinates where our measurements are
x = [7;12;6];
y = [11;5;2];

%load in the estimates & retime them to match the # of data points
load('C3.mat')
load('B5.mat')
load('B3.mat')
data = synchronize(C3,B5,B3);
data = retime(data,'hourly','mean');
data = rmmissing(data);

%Initialize a figure
h = figure;

%Initialize the background image
%I = imread('aerial_pods.png'); 

%create separate kriging maps for each instance of estimates
for i = 1:height(data)
    z = [data{i,1}; data{i,2}; data{i,3}];
    % calculate the sample variogram
    % note maxdist should be n/2
    v = variogram([x y],z,'plotit',false,'maxdist',12);
    % and fit a spherical variogram
    [~,~,~,vstruct] = variogramfit(v.distance,v.val,[],[],[],'model','stable');

    % now use the sampled locations in a kriging
    [Zhat,Zvar] = kriging(vstruct,x,y,z,X,Y);
    contour(X,Y,Zvar); 
    axis tight manual % this ensures that getframe() returns a consistent size
    filename = 'KrigingVarianceAnimatedTimeImg.gif';
    %axis image; axis xy
    title('Kriging Variance');
    colorbar
    caxis([0 0.1])

    %get the image behind the plot
    hold on
    I = imread('aerial_pods_muted.png'); 
    J = flip(I, 2);
    J = imrotate(J,180);
    k = image(xlim,ylim,J); 
    uistack(k,'bottom')

    %Add the date and time
    yourDate = data.fieldStruct_t(i);  % Perhaps a serial date number
    text(0.01,0.01, datestr(yourDate),'VerticalAlignment', 'bottom');

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