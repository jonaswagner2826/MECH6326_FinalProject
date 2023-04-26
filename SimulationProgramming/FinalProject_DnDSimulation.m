% clear; close all; %clc;

%% MECH 6326 Final Project: D&D Combat Simulation
% Alyssa Vellucci: AMV170001
% Jonas Wagner: JRW200000


recomputeP = false;
recalculate_pi_star = false;
runDNDvisualization = true;

% Sim Settings
const.finiteHorrizon = 50;
const.battlefieldsize = 15;
const.relPosMax = 5;


%% System Parameters
% PC Stats
const.pc.hp.max = 15;
const.pc.ac = 15;
const.pc.strength = 5;
const.pc.dext = 5;
% const.pc.speed = 1;
% Melee
const.pc.melee.range = 2;
const.pc.melee.weapon = 0;
const.pc.melee.d = 4;
% Ranged
const.pc.ranged.range = 5;
const.pc.ranged.weapon = 0;
const.pc.ranged.d = 6;
% Heal
const.pc.heal.baseheal = 1;
const.pc.heal.d = 4;

% Monster Stats
const.mn = const.pc; % Monster same stats
const.mn.heal = []; % Can't heal

%% Markov Chain Definitions
% Move 
const.move.stop = @(x) x;
const.move.N = @(x) x + [0;1];
const.move.E = @(x) x + [1;0];
const.move.S = @(x) x + [0;-1];
const.move.W = @(x) x + [-1;0];
% Diagonal movement
const.move.NE = @(x) x + [1;1];
const.move.NW = @(x) x + [-1;1];
const.move.SE = @(x) x + [1;1];
const.move.SW = @(x) x + [1;-1];

% Action
const.action.melee = 1;
const.action.ranged = 2;
const.action.heal = 3;
const.action.nothing = 4;

% Dice
D.d4 = (1/4)*ones(4,1);
D.d6 = (1/6)*ones(6,1);
D.d8 = (1/8)*ones(8,1);
D.d20 = (1/20)*ones(20,1);

% Actions
hp_max = max(const.pc.hp.max, const.mn.hp.max);
hp_states = 0:hp_max;
num_hp_states = length(hp_states);

% Relative Markov Chains
M = DND_construct_relative_markov(num_hp_states, const);


%% Dynamic Programming
% State Space
X.pos.x = -const.relPosMax:const.relPosMax; X.pos.y = X.pos.x;
X.pc.hp = 0:hp_max; X.mn.hp = 0:hp_max;
X.pc.potion = [0,1];
[X.values{1}, X.values{2}, X.values{3}, X.values{4}, X.values{5}] = ...
    ndgrid(X.pos.x, X.pos.y, X.pc.hp, X.mn.hp, X.pc.potion);
X.size = size(X.values{1});

% Input Space
U.move = fieldnames(const.move);
U.action = fieldnames(const.action);

%% Probability Update Computation
if recomputeP
    P = DND_construct_absolute_markov(hp_max, X, U, const, M);
    save("data/P_update","P")
elseif ~exist("P",'var')
    load("data/P_update.mat","P")
end

%% Finite Time Horrizon Calculation

% Stage Cost
g_k = @(pc_hp, mn_hp) -pc_hp;
G_k = arrayfun(@(pc_hp, mn_hp) g_k(pc_hp, mn_hp), X.values{3}, X.values{4});
G_k(:,:,1,:) = 1; % Don't want to die...
G_k(:,:,:,1) = -1; % Want monster to die...


if recalculate_pi_star
% Initialize optimal costs, policies
J_new = G_k;

N = const.finiteHorrizon; % Future Timesteps

tic
for k = N:-1:0
    k, toc, tic
    if k < N; pi_star{k+1} = pi_star_new; end

    % Cost function for each input
    for idx_move = 1:length(U.move)
        for idx_action = 1:length(U.action)

    J_future = arrayfun(@(P) P{:}'*reshape(J_new,[],1),...
        P{idx_move,idx_action});
    Ju(:,:,:,:,:,idx_move,idx_action) = G_k + J_future;
        end
    end

    % Optimal cost function and input
    [J_new, pi_star_idx] = min(Ju,[],[6,7],"linear");
    pi_star_new = arrayfun(...
        @(idx) pi_star_from_idx(idx, size(Ju), U), pi_star_idx);
end

    J_0 = J_new;
    pi_star_0 = pi_star_new; 
    save("data/pi_star","pi_star") 
    save("data/pi_star_0", "pi_star_0") 
elseif ~any([exist("pi_star","var"),exist("pi_star_0","var")])
    load("data/pi_star.mat","pi_star");
    load("data/pi_star_0.mat", "pi_star_0");
end

%% Simulation
% Setup
% Control Law
pi_k = @(x,pi_star) pi_star(...
    X.pos.x==x.pos.x,...
    X.pos.y==x.pos.y,...
    X.pc.hp==x.pc.hp,...
    X.mn.hp==x.mn.hp,...
    X.pc.potion==min(1,x.pc.potion));

% Intitial State
[x_0.pc.x, x_0.pc.y] = deal(1, 5); % x_pc_x and x_pc_y
[x_0.mn.x, x_0.mn.y] = deal(-2, 5); % x_mn_x and x_mn_y
x_0.pc.hp = const.pc.hp.max; % initial hp
x_0.mn.hp = const.mn.hp.max; % initial hp
x_0.pc.potion = 2;

% Run Sim
for rng_seed = [69, 420, 171, 2826, 1997]
rng(rng_seed);
results = DND_simulate_sys(x_0, pi_k, pi_star_0, const, pi_star);

% Single Result Plotting
if runDNDvisualization
% close all
figure
results.U(length(results.X)) = results.U(length(results.X) - 1);
animation_filename = ['figs/','DND_SingleSim_Animation','_rng_seed=',...
    num2str(rng_seed)];
v = VideoWriter([animation_filename,'.mp4'],'MPEG-4');
v.FrameRate = 1;
open(v);
for k = 1:length(results.X)
    plot_DND_visualization(results.X(k), results.U(k))
    ylim([0,10]);
    xlim([-4,4]);
    title("DND Simulation", ...
        ['Seed =', num2str(rng_seed),' Round =', num2str(k)])

    if results.X(k).pc.hp <=0
        hold on
        x = get(gca,'XLim');
        y = get(gca,'YLim');
        text(min(x),mean(y),'Game Over!',...
            'FontSize',25,'Color','red','BackgroundColor','yellow')
    elseif results.X(k).mn.hp <= 0
        hold on
        x = get(gca,'XLim');
        y = get(gca,'YLim');
        text(min(x),mean(y),'Game Won!', ...
            'FontSize',25,'Color','green','BackgroundColor','yellow')
    end

    drawnow
    frame = getframe(gcf);
    writeVideo(v,frame);

    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    if k == 1
        imwrite(imind,cm,[animation_filename,'.gif'],'gif', 'Loopcount',inf);
    else
        imwrite(imind,cm,[animation_filename,'.gif'],'gif','WriteMode','append');
    end
end
writeVideo(v,frame);
close(v);
end
end

%% Monte Carlo

num_sims = 1000;

% Initial conditions
clear x_0 X_0 monte_carlo_results monte_carlo_final;
[x_0.pc.x, x_0.pc.y] = deal(1, 5); % x_pc_x and x_pc_y
[x_0.mn.x, x_0.mn.y] = deal(-2, 5); % x_mn_x and x_mn_y
x_0.pc.hp = const.pc.hp.max; % initial hp
x_0.mn.hp = const.mn.hp.max; % initial hp
x_0.pc.potion = 2;

% Initialize arrays (will be overwritten)
monte_carlo_results(num_sims) = results;
monte_carlo_final(num_sims) = results(end).X(end);
X_0(num_sims) = x_0;

% Run sims
for i = 1:num_sims
    rng(i)
   
    X_0(i) = x_0;
    X_0(i).pc.x = datasample(-const.battlefieldsize:const.battlefieldsize,1);
    X_0(i).mn.x = X_0(i).pc.x + datasample(X.pos.x,1);
    X_0(i).pc.y = datasample(-const.battlefieldsize:const.battlefieldsize,1);
    X_0(i).mn.y = X_0(i).pc.y + datasample(X.pos.y,1);
    
    monte_carlo_results(i) = DND_simulate_sys(...
        X_0(i), pi_k, pi_star_0, const, pi_star);
end

% Monte Carlo Results 
X_final.pc.hp = arrayfun(@(result) ...
    result.X(end).pc.hp, monte_carlo_results);
X_final.mn.hp = arrayfun(@(result) ...
    result.X(end).mn.hp, monte_carlo_results);

%% Visualize Monte Carlo
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
saveas(gcf,"figs/DND_MonteCarlo_winlosstie.png")

% Monte-Carlo Results
figure
hold on
histogram(X_final.pc.hp(all([X_final.pc.hp>0;X_final.mn.hp==0])))
histogram(-X_final.mn.hp(all([X_final.mn.hp>0;X_final.pc.hp==0])))
title("Monte-Carlo Simulation Results")
xlabel('Final HP State')
ylabel('# of Simulations')
legend('Monster Dies: PC HP', 'PC Dies: Monster HP')

saveas(gcf,"figs/DND_MonteCarlo_Hist.png")

%% Extra functions
function pi_star = pi_star_from_idx(idx,size_Ju, U)
    [~,~,~,~,~,idx_move,idx_action] = ind2sub(size_Ju,idx);
    pi_star.move = U.move{idx_move};
    pi_star.action = U.action{idx_action};
end



