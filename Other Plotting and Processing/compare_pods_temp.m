temp = timetable(fieldStruct_t,fieldStruct_X.temperature);
temp=retime(temp,'hourly','mean');
temp.Properties.VariableNames{1} = 'temp';
temp = timetable2table(temp);
temp.temp=round(temp.temp,0);
temp=table2timetable(temp);

afield=timetable(field.fieldStruct_t,field.subtracted);
afield=retime(afield,'hourly','mean');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%syn.Properties.VariableNames{3} = 'temp';

newfield=timetable(field.AM,field.subtracted);
newfield=retime(newfield,'hourly','mean');

syn=synchronize(afield,newfield,temp);
syn=rmmissing(syn);

c= max(temp.temp) - min(temp.temp);

s = gscatter(syn.Var1_afield,syn.Var1_newfield,syn.temp,jet(c),'.',20);

xlabel('CH4');
ylabel('CO2');
title('MW1 CO2');
xlim([0 0.7])
ylim([0 120])
%refline(1,0);
savefig('MW1 CO2 Comparison - Temperature.fig');