%if neccessary - convert to timetable & make minutely
% field=table2timetable(B6corrected);
% field=retime(field,'minutely','mean');
% field=rmmissing(field);

%initialize the baseline array
baseline=[];
%assuming field is already a minutely timetable
% Initialize the array for the baseline
mins = size(field,1);

% Iterate through each minute (ii), using 180 minute windows from minute (ii) to (ii + 180) to find baseline
for ii = 1:180:mins-1 
    %if there's more than 100 data points present
    if ii < mins-180
        win40 = field(ii:ii+180,:); % Find 100 minute running window
        %fit the kernel distribution
        [f,xi] = ksdensity(win40.Y_hatfield_k); 
        %find the 25th percentile of the distribution
        %desiredp = prctile(f,75); 
        desiredp=xi(1,25);
        %replace all those values with the new number
        newfield = desiredp.* ones(180,1);
        baseline = [baseline; newfield];
        
     %uses this portion if there's less than 180 points left
     elseif ii >= mins-180
        %calculate how many points are left
        remain = mins - ii +1;
        %takes in however many points are remaining
        win40 = field(ii:mins-1,:); % Use the remaining data if less than 100 minutes exist after minute (ii)
        %the rest is all the same
        %fit the kernel distribution
        [f,xi] = ksdensity(win40.Y_hatfield_k); 
        %find the 25th percentile of the distribution
        %desiredp = prctile(f,50);
        desiredp=xi(1,25);
        %replace all those values with the new number
        newfield = desiredp.* ones(remain,1);
        baseline = [baseline; newfield];

     end

    
end
%apply smoothing function to complete baseline data
yy = smooth(baseline);

%save the baseline and baseline subtracted arrays
field.baseline = yy;
field.subtracted=field.Y_hatfield_k - yy;

%remove the negatives and save
field.subtracted(field.subtracted<0)=NaN;
field=rmmissing(field);
save('methane_baseline.mat','field');
clear
