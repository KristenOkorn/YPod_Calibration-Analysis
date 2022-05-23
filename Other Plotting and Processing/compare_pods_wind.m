w=table2timetable(WindRoseData);
w=rmmissing(w);
w=retime(w,'hourly','mean');

syn2=synchronize(syn,w);
syn2=rmmissing(syn2);
syn2=timetable2table(syn2);

s=gscatter(syn2.Var1_afield,syn2.Var1_newfield,syn2.Direction,hsv,'.',24);

xlabel('MW4');
ylabel('MW3');
xlim([0 0.35])
ylim([0 0.35])
refline(1,0);
savefig('MW3 MW4 Comparison - Wind.fig');