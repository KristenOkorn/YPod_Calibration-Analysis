%% POD_data_to_DB_v2
%{
By Evan R. Coffey

Version 2.0, December 9, 2021
(this version could benefit from minimizing the memory size of the DB)


Saves calibrated colocation (1,2) and/or field POD data* from a deployment into a
local SQLite database (or shared folder if syncing through a desktop client).

One unique database (timestamped, in UTC) is created each time the MainPodCode is run with
database saving option selected. If this script is run independently of
MainPodCode, the user will be asked to select a MainPodCode 'Outputs'
folder manually. *ONLY data from PodID's mentioned in the SettingsSet.mat
file in the relevant Outputs folder will be saved to the database.

Within each database, there can be a total of 3 tables; 'Colocation1_calibrated',
'Colocation2_calibrated', and 'Field_calibrated', representing the 3 modes
of pod data (as of Dec 2021). As of now, ANN models are NOT saved to DB.

Data within each database can be queried (i.e., 'fetch' etc) and analysed using
seperate code.

A "columnkey" field (i.e., column in a DB table) is stored at the start of every record (row in a DB table) to
reflect the column headers of that record

Additonal resources:
https://www.sqlite.org/index.html
https://www.w3schools.com/sql/default.asp
https://www.mathworks.com/help/database/ug/working-with-the-matlab-interface-to-sqlite.html
https://www.mathworks.com/help/database/ug/import-data-using-the-matlab-interface-to-sqlite.html
https://towardsdatascience.com/mysql-vs-sqlite-ba40997d88c5

%}


%% Start script
% Inform user that data is being saved to DB
try
    disp('Saving data to a database...')
time_added_to_DB = datetime('now', 'Format','yyyy MM dd HH mm', 'TimeZone','local');   % Local Time Zone
time_added_to_DB.TimeZone = 'Z'; %convert to UTC
time_added_to_DB = datestr(time_added_to_DB, 'mm_dd_YYYY_HH_MM');
time_added_to_DB = strcat(time_added_to_DB, '_UTC');
catch
    time_added_to_DB = 'time_error';
end

%Automatically creates a SQLite database (DB) file in the MainPodCode 'Output' folder unless this code is run
% independently of the MainPodCode, then asks user to select the 'Output' folder.

try
datapath = fullfile(settingsSet.outpath); %if MainPodCode was just run this should be current
catch
    disp('...no current folder path was detected') %if MainPodCode was not run, user is asked to select an Output Folder with the data 
    datapath = uigetdir(pwd,'Select an "Output Folder" from MainPodCode');
end


try
    conn = sqlite(fullfile(datapath,strcat('POD_DB_',time_added_to_DB,'.db')),'create'); %Create and connect to generated Pod DB
    disp('database created...connection to POD database successful')
catch
    disp('...issue encountered creating a new POD database')
end


%% Query the output directory folder and load SettingsSet variable to locate pod files

foldercontents = dir(datapath);
try
    load(fullfile(datapath,"SettingsSet.mat")) %load in the SettingsSet mat file
catch
    disp(['failed saving any data to database: No "SettingsSet.mat" file located in ', datapath]);
end

%Inspect the SettingSet variable to determine unique DB table fields (this is unique to how MainPodCode was specified to run)
try
    settings_var_list = tempdata.Properties.VariableNames;
    if width(settings_var_list)<=38 %some columns in the SettingsSet have not been ungrouped if 35 or less fields
        tempdata = splitvars(tempdata, 'datetimestrs');
        tempdata = splitvars(tempdata, 'datestrings');
        tempdata = splitvars(tempdata, 'podSensors');
        tempdata = splitvars(tempdata, 'envSensors');
        tempdata = splitvars(tempdata, 'refPreProcess');
        tempdata = splitvars(tempdata, 'podPreProcess');
        tempdata = splitvars(tempdata, 'statsList');
        tempdata = splitvars(tempdata, 'plotsList');
        tempdata = splitvars(tempdata, 'podList');
        settings_var_list = tempdata.Properties.VariableNames;
    end
catch
    settings_var_list = SettingsSet.Properties.VariableNames; %if the variable name is not 'tempdata'
    if width(settings_var_list)<=38 %some columns in the SettingsSet have not been ungrouped if 35 or less fields
        SettingsSet = splitvars(SettingsSet, 'datetimestrs');
        SettingsSet = splitvars(SettingsSet, 'datestrings');
        SettingsSet = splitvars(SettingsSet, 'podSensors');
        SettingsSet = splitvars(SettingsSet, 'envSensors');
        SettingsSet = splitvars(SettingsSet, 'refPreProcess');
        SettingsSet = splitvars(SettingsSet, 'podPreProcess');
        SettingsSet = splitvars(SettingsSet, 'statsList');
        SettingsSet = splitvars(SettingsSet, 'plotsList');
        SettingsSet = splitvars(SettingsSet, 'podList');
        settings_var_list = SettingsSet.Properties.VariableNames;
    end
end

% Inspect the SettingSet variable to determine unique DB table fields
%Obtain all Pod IDs involved
try
pod_ids = tempdata(1,find(contains(settings_var_list, 'podList'))); %#ok<FNDSB> 
num_pods = width(pod_ids);
catch
    pod_ids = SettingsSet(1,find(contains(settings_var_list, 'podList'))); %#ok<FNDSB> 
    num_pods = width(pod_ids);
end


%% Prepare pod calibration/calibrated data for database

col1_table_to_insert = table();
col2_table_to_insert = table();
field_table_to_insert = table();


%Loop through Contents of output folder for matches of pod Colocation and/or Field files and append SettingsSet data to records
for i=1:num_pods
current_pod_id = char(pod_ids.(i));


%find any primary Colocation data for current pod
try
    colocation1_pod_var = foldercontents(contains({foldercontents.name},strcat(current_pod_id,'_Colocation.'))); %modify this if output naming changes

    %append SettingsSet data to each record in colocation_pod_vars
    if ~isempty(colocation1_pod_var)  
    load(fullfile(colocation1_pod_var.folder,colocation1_pod_var.name))
    SettingsSet_temp = repmat(tempdata,height(X),1);
    col1_table_to_insert_temp = [X, SettingsSet_temp];
    col1_table_to_insert = [col1_table_to_insert; col1_table_to_insert_temp]; %#ok<AGROW> %append by podID
    clear col1_table_to_insert_temp SettingsSet_temp colocation1_pod_var X
    else
    end
catch
        disp(['issue compliling colocation 1 data for ',current_pod_id, ' to import to database...skipping'])
end

%find any secondary Colocation data for current pod
try
    colocation2_pod_var = foldercontents(contains({foldercontents.name},strcat(current_pod_id,'_Colocation2.'))); %modify this if output naming changes

    %append SettingsSet data to each record in colocation2_pod_vars
    if ~isempty(colocation2_pod_var)  
    load(fullfile(colocation2_pod_var.folder,colocation2_pod_var.name))
    SettingsSet_temp = repmat(tempdata,height(X),1);
    col2_table_to_insert_temp = [X, SettingsSet_temp];
    col2_table_to_insert = [col2_table_to_insert; col2_table_to_insert_temp]; %#ok<AGROW> %append by podID
    clear col2_table_to_insert_temp SettingsSet_temp colocation2_pod_var X
    else
    end
catch
        disp(['issue compliling colocation 2 data for ',current_pod_id, ' to import to database...skipping'])
end


%find any Field data for current pod
try
    field_pod_var = foldercontents(contains({foldercontents.name},strcat(current_pod_id,'_Field.'))); %modify this if output naming changes

    %append SettingsSet data to each record in colocation2_pod_vars
    if ~isempty(field_pod_var)  
    load(fullfile(field_pod_var.folder,field_pod_var.name))
    SettingsSet_temp = repmat(tempdata,height(X),1);
    field_table_to_insert_temp = [X, SettingsSet_temp];
    field_table_to_insert = [field_table_to_insert; field_table_to_insert_temp]; %#ok<AGROW> %append by podID
    clear field_table_to_insert_temp SettingsSet_temp field_pod_var X
    else
    end
catch
        disp(['issue compliling field data for ',current_pod_id, ' to import to database...skipping'])
end

%Could add ANN models here later if needed

end
    clear colocation1_pod_var col1_table_to_insert_temp SettingsSet_temp colocation1_pod_var X col2_table_to_insert_temp SettingsSet_temp colocation2_pod_var X
    clear field_pod_var field_table_to_insert_temp SettingsSet_temp field_pod_var X current_pod_id pod_ids num_pods

%% Create DB table for raw POD data if it doesn't already exist
% to be added
    
%% Create DB table for calibration/calibrated POD data if it doesn't already exist

% Primary Colocation Data table


if ~isempty(col1_table_to_insert)
try
    %Add a column key for DB organization
    col1_table_to_insert.columnkey = NaN(height(col1_table_to_insert),1);
    col1_table_to_insert = movevars(col1_table_to_insert,'columnkey','Before',1);
    col1_table_to_insert.columnkey = repmat(strjoin(col1_table_to_insert.Properties.VariableNames,','),height(col1_table_to_insert),1);
   
    %Data requiring reformatting for DB
    temppy = col1_table_to_insert;
    temppy.time = char(datestr(temppy.time, 'mm/dd/yyyy HH:MM:SS'));
    temppy.equation = char(temppy.equation);
    temppy.loadOldSettings = double(temppy.loadOldSettings);
    temppy.convertOnly = double(temppy.convertOnly);
    temppy.applyCal = double(temppy.applyCal);
    temppy.database = double(temppy.database);
    temppy.ispc = double(temppy.ispc);
    temppy = table2cell(temppy);
    
    DB_table_fields = transpose(col1_table_to_insert.Properties.VariableNames);
    DB_table_datatype = cell(length(DB_table_fields),1); DB_table_datatype(:) = {'VARCHAR'};
    DB_table_input = transpose(strcat(DB_table_fields, {' '}, DB_table_datatype, {', '}));
    DB_final_table_input = cell2mat(DB_table_input);
    DB_final_table_input(end-1:end)=[];

    %Specify the name and columns of the colocation1 table to be inserted, then
    %create and populate
    DB_table_name = strcat('Colocation1_calibrated');
    createTable = char(strcat('create table'," ", DB_table_name,' (', DB_final_table_input,')'));
    exec(conn,createTable);
    insert(conn,'Colocation1_calibrated',col1_table_to_insert.Properties.VariableNames,temppy)

    %test = fetch(conn,char(strcat('SELECT * FROM', " ", DB_table_name)));

    clear temppy DB_table_fields DB_table_datatype DB_table_input DB_final_table_input DB_table_name createTable
    disp('Colocation 1 data saved to database successfully')

catch
    disp('issue saving colocation1 data: check output .mat files')
end
else
    disp('No colocation1 data found to save to database')
end

% Secondary Colocation Data table
if ~isempty(col2_table_to_insert)
try
    %Add a column key for DB organization
    col2_table_to_insert.columnkey = NaN(height(col2_table_to_insert),1);
    col2_table_to_insert = movevars(col2_table_to_insert,'columnkey','Before',1);
    col2_table_to_insert.columnkey = repmat(strjoin(col2_table_to_insert.Properties.VariableNames,','),height(col2_table_to_insert),1);
   
    %Data requiring reformatting for DB
    temppy = col2_table_to_insert;
    temppy.time = char(datestr(temppy.time, 'mm/dd/yyyy HH:MM:SS'));
    temppy.equation = char(temppy.equation);
    temppy.loadOldSettings = double(temppy.loadOldSettings);
    temppy.convertOnly = double(temppy.convertOnly);
    temppy.applyCal = double(temppy.applyCal);
    temppy.database = double(temppy.database);
    temppy.ispc = double(temppy.ispc);
    temppy = table2cell(temppy);

    DB_table_fields = transpose(col2_table_to_insert.Properties.VariableNames);
    DB_table_datatype = cell(length(DB_table_fields),1); DB_table_datatype(:) = {'VARCHAR'};
    DB_table_input = transpose(strcat(DB_table_fields, {' '}, DB_table_datatype, {', '}));
    DB_final_table_input = cell2mat(DB_table_input);
    DB_final_table_input(end-1:end)=[];

    %Specify the name and columns of the colocation2 table to be inserted, then
    %create and populate    
    DB_table_name = strcat('Colocation2_calibrated');
    createTable = char(strcat('create table'," ",DB_table_name,' (', DB_final_table_input,')'));
    exec(conn,createTable);
    insert(conn,DB_table_name,col2_table_to_insert.Properties.VariableNames,temppy)

    %test = fetch(conn,char(strcat('SELECT * FROM', " ", DB_table_name)));

    clear temppy DB_table_fields DB_table_datatype DB_table_input DB_final_table_input DB_table_name createTable
    disp('Colocation 2 data saved to database successfully')

catch
    disp('issue saving colocation2 data: check output .mat files')
end
else
    disp('No colocation2 data found to save to database')
end

% Field Data table
if ~isempty(field_table_to_insert)
try
    %Add a column key for DB organization
    field_table_to_insert.columnkey = NaN(height(field_table_to_insert),1);
    field_table_to_insert = movevars(field_table_to_insert,'columnkey','Before',1);
    field_table_to_insert.columnkey = repmat(strjoin(field_table_to_insert.Properties.VariableNames,','),height(field_table_to_insert),1);
   
    %Data requiring reformatting for DB
    temppy = field_table_to_insert;
    temppy.time = char(datestr(temppy.time, 'mm/dd/yyyy HH:MM:SS'));
    temppy.equation = char(temppy.equation);
    temppy.loadOldSettings = double(temppy.loadOldSettings);
    temppy.convertOnly = double(temppy.convertOnly);
    temppy.applyCal = double(temppy.applyCal);
    temppy.database = double(temppy.database);
    temppy.ispc = double(temppy.ispc);
    temppy = table2cell(temppy);
    
    DB_table_fields = transpose(field_table_to_insert.Properties.VariableNames);
    DB_table_datatype = cell(length(DB_table_fields),1); DB_table_datatype(:) = {'VARCHAR'};
    DB_table_input = transpose(strcat(DB_table_fields, {' '}, DB_table_datatype, {', '}));
    DB_final_table_input = cell2mat(DB_table_input);
    DB_final_table_input(end-1:end)=[];

    %Specify the name and columns of the field table to be inserted, then
    %create and populate
    DB_table_name = strcat('Field_calibrated');
    createTable = char(strcat('create table', " ", DB_table_name,' (', DB_final_table_input,')'));
    exec(conn,createTable);
    insert(conn,DB_table_name,field_table_to_insert.Properties.VariableNames,temppy)
 
    %test = fetch(conn,char(strcat('SELECT * FROM', " ", DB_table_name)));

    clear DB_table_fields DB_table_datatype DB_table_input DB_final_table_input DB_table_name createTable
    disp('Field data saved to database successfully')

catch
    disp('issue saving field data: check output .mat files')
end
else 
    disp('No field data found to save to database')
end


%% Close the DB connection
try close(conn)
catch
end





