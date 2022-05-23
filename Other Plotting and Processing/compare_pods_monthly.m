afield=timetable(field.fieldStruct_t,field.subtracted);
afield=retime(afield,'hourly','mean');

newfield=timetable(field.fieldStruct_t,field.subtracted);
newfield=retime(newfield,'hourly','mean');

afield=table2timetable(afield);
newfield=table2timetable(newfield);

afield=retime(afield,'hourly','mean');
newfield=retime(newfield,'hourly','mean');

syn=synchronize(afield,newfield);
syn=rmmissing(syn);


Month = month(syn.fieldStruct_t);
month=array2table(Month);
syn= [syn month];
syn=rmmissing(syn);
s=gscatter(syn.subtracted_afield,syn.subtracted_newfield,syn.Month,hsv(3),'.',24);

xlabel('MW1');
ylabel('ME1');
%title('AC1')
xlim([0 0.6])
ylim([0 0.6])
refline(1,0);
savefig('MW1 ME1 Comparison - Baseline Removed 50p- Monthly.fig');
