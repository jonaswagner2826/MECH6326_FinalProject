function plot_DND_sim_results(results_array, sim_name)
% Visualize Player Results
X_final.pc.hp = arrayfun(@(result) ...
    result.X(end).pc.hp, results_array);
X_final.mn.hp = arrayfun(@(result) ...
    result.X(end).mn.hp, results_array);

% Win loss tie
figure;
hold on
names = {'PC and Monster Live','Monster Dies, PC Lives', 'Monster Lives, PC Dies'};
x = [1:3];
y = [sum(all([X_final.mn.hp>0;X_final.pc.hp>0])),
    sum(all([X_final.mn.hp==0;X_final.pc.hp>0])),
    sum(all([X_final.mn.hp>0;X_final.pc.hp==0]))];
bar(x,y)
set(gca,'XTick',1:length(names),'XTickLabel',names)
ylabel('# of Simulations');
title([sim_name, ' Attempts'])
saveas(gcf,['figs/DND_',...
    strrep(strrep(strrep(lower(sim_name),' ','_'),'(',''),')',''),...
    '_winlosstie.png'])

% Monte-Carlo Results
figure
hold on
histogram(X_final.pc.hp(all([X_final.pc.hp>0;X_final.mn.hp==0])))
histogram(-X_final.mn.hp(all([X_final.mn.hp>0;X_final.pc.hp==0])))
title([sim_name, ' Simulation Results'])
xlabel('Final HP State')
ylabel('# of Simulations')
legend('Monster Dies: PC HP', 'PC Dies: Monster HP')

saveas(gcf,['figs/DND_',...
    strrep(strrep(strrep(lower(sim_name),' ','_'),'(',''),')',''),...
    '_hist.png'])
end