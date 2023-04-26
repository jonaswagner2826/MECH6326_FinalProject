% clear; close all; %clc;

%% MECH 6326 Final Project: D&D Combat Simulation
% Alyssa Vellucci: AMV170001
% Jonas Wagner: JRW200000


recomputeP = false;
recalculate_pi_star = false;
runDNDvisualization = true;

% Sim Settings
const.finiteHorrizon = 25;
const.battlefieldsize = 15;
rng_seed = 420;


%% System Parameters
const.pc.melee.range = 2;
const.pc.melee.weapon = 0;
const.pc.melee.d = 4;
const.pc.ranged.range = 5;
const.pc.ranged.weapon = 0;
const.pc.ranged.d = 6;
const.pc.speed = 1;
const.pc.ac = 12;%15;
const.pc.strength = 5;
const.pc.dext = 5;
const.pc.hp.max = 10;
const.mn = const.pc; % same stats

% For testing... (or final?)
% const.mn.hp.max = 10;
% const.mn.ac = 10;
% const.mn.melee.weapon = 3;
% const.mn.ranged.weapon = 0;

const.pc.heal.baseheal = 1;
const.pc.heal.d = 4;

% Pi_star Setup
const.relPosMax = 5;
const.finiteHorrizon = 15;

%% Markov Chain Definitions
% Move 
const.move.stop = @(x) x;
const.move.N = @(x) x + [0;1];
const.move.E = @(x) x + [1;0];
const.move.S = @(x) x + [0;-1];
const.move.W = @(x) x + [-1;0];
% diagonal movement...
% const.move.NE = @(x) x + [1;1];
% const.move.NW = @(x) x + [-1;1];
% const.move.SE = @(x) x + [1;1];
% const.move.SW = @(x) x + [1;-1];

% Action
const.action.melee = 1;
const.action.ranged = 2;
const.action.heal = 3;
const.action.nothing = 4;

% Dice (not really used)
% D.d2 = (1/2)*ones(2,1);
D.d4 = (1/4)*ones(4,1);
D.d6 = (1/6)*ones(6,1);
D.d8 = (1/8)*ones(8,1);
% D.d10 = (1/10)*ones(10,1);
D.d20 = (1/20)*ones(20,1);
% D.d100 = (1/100)*ones(100,1);
D.diceRoll = [4; 6; 8; 20];
D.diceRoll = [D.diceRoll; D.diceRoll];

% Actions
hp_max = max(const.pc.hp.max, const.mn.hp.max);
hp_states = 0:hp_max;
num_hp_states = length(hp_states);

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



%% Finite Time Horrizon

% Stage Cost
g_k = @(pc_hp, mn_hp) -pc_hp;%-3*(pc_hp - mn_hp);% - 2*pc_hp;
% g_k = @(pc_hp, mn_hp) - 2*pc_hp;
G_k = arrayfun(@(pc_hp, mn_hp) g_k(pc_hp, mn_hp), X.values{3}, X.values{4});
G_k(:,:,1,:) = 1; % Don't want to die...
G_k(:,:,:,1) = -1; % Want monster to die...
% G_k([1 end],:,:,:) = hp_max; % Don't run away
% G_k(:,[1 end],:,:) = hp_max; % Don't run away




if recalculate_pi_star
% Initialize optimal costs, policies
% J = zeros(length(X.pos.x),length(X.pos.y),...
%     length(X.pc.hp),length(X.mn.hp),length(X.pc.potion));
% J_new = ones(size(J));
% J_new = 10*G_k; % last step important
J_new = G_k;

N = const.finiteHorrizon; % Future Timesteps
% clear pi_star; clear J; % for finite version

tic
for k = N:-1:0
    k, toc, tic
    % J{k+1} = J_new;
    if k < N; pi_star{k+1} = pi_star_new; end

    % Cost function for each input
    for idx_move = 1:length(U.move)
        for idx_action = 1:length(U.action)

    J_future = arrayfun(@(P) P{:}'*reshape(J_new,[],1),...
        P{idx_move,idx_action});
    Ju(:,:,:,:,:,idx_move,idx_action) = G_k + J_future; 

        % idx_move, idx_action
        
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
% x_0.pos.x = x_0.pc.x - x_0.mn.x; % relative x position
% x_0.pos.y = x_0.pc.y - x_0.mn.y; % relative y position
x_0.pc.hp = const.pc.hp.max; % initial hp
x_0.mn.hp = const.mn.hp.max; % initial hp
x_0.pc.potion = 2;

% Run Sim
for rng_seed = [69, 420, 171, 2826, 1997]
% rng_seed = 2826;
rng(rng_seed);
results = DND_simulate_sys(x_0, pi_k, pi_star_0, const, pi_star);

% Single Result Plotting
if runDNDvisualization
% close all
figure
results.U(length(results.X)) = results.U(length(results.X) - 1);
animation_filename = ['figs/','DND_SingleSim_Animation','_rng_seed=',...
    num2str(rng_seed),'.mp4'];
v = VideoWriter(animation_filename,'MPEG-4');
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
    % im = frame2im(frame);
    % [imind,cm] = rgb2ind(im,256);
    % if k == 1
    %     imwrite(imind,cm,animation_filename,'gif', 'Loopcount',inf);
    % else
    %     imwrite(imind,cm,animation_filename,'gif','WriteMode','append');
    % end

    % pause(0.5)
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

%% hp_results = 
X_final.pc.hp = arrayfun(@(result) ...
    result.X(end).pc.hp, monte_carlo_results);
X_final.mn.hp = arrayfun(@(result) ...
    result.X(end).mn.hp, monte_carlo_results);

figure;
hold on
histogram(X_final.pc.hp(all([X_final.pc.hp>0;X_final.mn.hp==0])), ...
    "DisplayName","PC Wins")
histogram(-X_final.mn.hp(all([X_final.mn.hp>0;X_final.pc.hp==0])), ...
    "DisplayName","Monster Wins")
bar(X_final.pc.hp(all([X_final.mn.hp>0;X_final.pc.hp>0]))...
    - X_final.mn.hp(all([X_final.mn.hp>0;X_final.pc.hp>0])), ...
    "DisplayName","Neither Wins")
title("Monte-Carlo Simulation Results")
xlabel("HP_{PC} - HP_{MN}","Interpreter","tex")
ylabel("Number of Sims")
legend

saveas(gcf,"figs/DND_MonteCarlo_Hist.png")

%% Extra functions
function pi_star = pi_star_from_idx(idx,size_Ju, U)
    [~,~,~,~,~,idx_move,idx_action] = ind2sub(size_Ju,idx);
    pi_star.move = U.move{idx_move};
    pi_star.action = U.action{idx_action};
end



