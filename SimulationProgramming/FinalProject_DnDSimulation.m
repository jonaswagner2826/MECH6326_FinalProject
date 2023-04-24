clear; close all; %clc;

%% MECH 6326 Final Project: D&D Combat Simulation
% Alyssa Vellucci: AMV170001
% Jonas Wagner: JRW200000


recomputeP = true;
recalculate_pi_star = true;

% sim length
simLength = 15;
rng_seed = 25;


%% System Parameters
const.pc.melee.range = 2;
const.pc.melee.weapon = 0;
const.pc.melee.d = 4;
const.pc.ranged.range = 5;
const.pc.ranged.weapon = 0;
const.pc.ranged.d = 6;
const.pc.speed = 1;
const.pc.ac = 17;%15;
const.pc.strength = 5;
const.pc.dext = 5;
const.pc.hp.max = 15;
const.mn = const.pc; % same stats

% For testing... (or final?)
% const.mn.hp.max = 10;
% const.mn.ac = 10;
% const.mn.melee.weapon = 3;
% const.mn.ranged.weapon = 0;

const.pc.heal.baseheal = 1;
const.pc.heal.d = 4;

% %Battlefield Set-Up
% battlefield_size = 50;
% grid = zeros(battlefield_size, battlefield_size); %create battlefield

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
hp_max = max(const.pc.hp.max,const.mn.hp.max);
hp_states = 0:hp_max;
num_hp_states = length(hp_states);

% PC
% Melee
M.pc.melee = zeros(num_hp_states);%(const.mn.ac - const.pc.strength)*eye(num_hp_states);
P_w_sf = [0.45,0.55]; % cheating... need to update this
for j = 1:num_hp_states
    M.pc.melee(j,j) = P_w_sf(1);
    for d = 1:const.pc.melee.d
        i = j - const.pc.melee.weapon - d;
        if i < 1; i = 1;end %zero out any negative states
        M.pc.melee(i,j) = M.pc.melee(i,j) + P_w_sf(2)/const.pc.melee.d;
    end
end
M.pc.melee = M.pc.melee';

% Ranged
M.pc.ranged = zeros(num_hp_states);%(const.mn.ac - const.pc.strength)*eye(num_hp_states);
P_w_sf = [0.45,0.55]; % cheating... need to update this
for j = 1:num_hp_states
    M.pc.ranged(j,j) = P_w_sf(1);
    for d = 1:const.pc.ranged.d
        i = j - const.pc.ranged.weapon - d;
        if i < 1; i = 1;end %zero out any negative states
        M.pc.ranged(i,j) = M.pc.ranged(i,j) + P_w_sf(2)/const.pc.ranged.d;
    end
end
M.pc.ranged = M.pc.ranged';
% Heal
% M.pc.heal.amount = @(w_d4) const.potion.baseheal + w_d4;
M.pc.heal = zeros(num_hp_states);
M.pc.heal(1,1) = 1;
for j = 2:num_hp_states
    for d = 1:const.pc.heal.d
        i = j + const.pc.heal.baseheal + d;
        if i > num_hp_states; i = num_hp_states; end
        M.pc.heal(i,j) = M.pc.heal(i,j) + (1/const.pc.heal.d);
    end
end
M.pc.heal = M.pc.heal';

% Nothing
M.pc.nothing = eye(num_hp_states);

% Monster
M.mn = M.pc; % same attack assumption (could redefine to be different)
M.mn.heal = M.pc.nothing; % Heal not possible

%% Dynamic Programming
% Infinite Horizon, Value Iteration

% State Space
const.relPosMax = 6;
X.pos.x = -const.relPosMax:const.relPosMax; X.pos.y = X.pos.x;
X.pc.hp = 0:hp_max; X.mn.hp = 0:hp_max;
[X.values{1}, X.values{2}, X.values{3}, X.values{4}] = ...
    ndgrid(X.pos.x, X.pos.y, X.pc.hp, X.mn.hp);
X.size = size(X.values{1});

% Input Space
U.move = fieldnames(const.move);
U.action = fieldnames(const.action);

%% Probability Update Computation
tic
if recomputeP
    % Update Probabilities update computation
    hp_eye = eye(hp_max+1);
    x_eye = eye(length(X.pos.x)); y_eye = eye(length(X.pos.y));
    P{length(U.move),length(U.action)} = [];
    P{length(U.move),length(U.action)} = {};
    % P_move{length(U.move),length(U.action)} = [];
    for idx_move = 1:length(U.move); u.move = const.move.(U.move{idx_move});
        for idx_action = 1:length(U.action); u.action = const.action.(U.action{idx_action});

        idx_move, idx_action, toc, tic
        
            P{idx_move,idx_action}{...
                X.size(1), X.size(2), X.size(3), X.size(4)} = [];
    
            for idx_x = 1:length(X.pos.x); x.pos.x = X.pos.x(idx_x);
                for idx_y = 1:length(X.pos.y); x.pos.y = X.pos.x(idx_y);
                    for idx_pc_hp = 1:length(X.pc.hp); x.pc.hp = hp_eye(:,idx_pc_hp);
                        for idx_mn_hp = 1:length(X.mn.hp); x.mn.hp = hp_eye(:,idx_mn_hp);
        % this creates the probability at all posible things...
        x_new = DND_markov_update(x,u,M,const);

    P_temp = zeros(prod(X.size),1);
    P_temp(sub2ind(...
        X.size,x_new.idx.x,x_new.idx.y,1,1)+(1:prod(X.size(3:4)))) = ...
        x_new.pc.hp*x_new.mn.hp';
    P{idx_move,idx_action}{idx_x,idx_y,idx_pc_hp,idx_mn_hp} = sparse(P_temp);
                        end
                    end
                end
            end
        end
    end
    save("P_update","P")
else
    load("P_update.mat")
end



%% Infinite Time Horrizon
% Initialize optimal costs, policies
J = zeros(length(X.pos.x),length(X.pos.y),length(X.pc.hp),length(X.mn.hp));
% pi_star(size(J)) = [];%[struct{'move',0,'action',0}];%.move = zeros(size(J)); pi_star.action = zeros(size(J));
J_new = ones(size(J));

% Stage Cost
g_k = @(pc_hp, mn_hp) -3*(pc_hp - mn_hp) - 2*pc_hp;
G_k = arrayfun(@(pc_hp, mn_hp) g_k(pc_hp, mn_hp), X.values{3}, X.values{4});
G_k(:,:,1,:) = 10; % Don't want to die...
G_k(:,:,:,1) = -10; % Want monster to die...
% G_k([1 end],:,:,:) = hp_max; % Don't run away
% G_k(:,[1 end],:,:) = hp_max; % Don't run away

J_new = 10*G_k; % last step important


if recalculate_pi_star
% t = 0; %value iteration counter
N = simLength; % Future Timesteps
% max_iter = 100;
% pi_star_new = pi_star; 
clear pi_star; clear J; % for finite version
tic
J_diff = 0;
pi_star_diff = 0;
% while norm(J - J_new,'fro') >= 1e-6
for k = N:-1:0
    toc
    tic
    J{k+1} = J_new;
    if k < N; pi_star{k+1} = pi_star_new; end

    % Cost function for each input
    for idx_move = 1:length(U.move)
        for idx_action = 1:length(U.action)

    J_future = arrayfun(@(P) P{:}'*reshape(J{k+1},[],1),...
        P{idx_move,idx_action});
    Ju(:,:,:,:,idx_move,idx_action) = (1/k)*G_k + J_future;

        % idx_move, idx_action
        end
    end

    % Optimal cost function and input
    [J_new, pi_star_idx] = min(Ju,[],[5,6],"linear");
    % [pi_star_new.move,p_star_new.action] = arrayfun(...
    pi_star_new = arrayfun(...
        @(idx) pi_star_from_idx(idx, size(Ju), U), pi_star_idx);
    
    if k < N
    % % t = t+1; % Count iterations
    % J_diff_new = norm(J{k+1} - J_new,'fro'); % how much increased/decreased
    % % J_diff_new = norm(J - J_new,'fro'); % how much increased/decreased
    % J_diff_from_last = J_diff_new - J_diff; % how different is this from last one...
    % J_diff = J_diff_new;
    % 
    % pi_star_diff_new = norm([pi_star{k+1}.move] - [pi_star_new.move],'fro'); % how much increased/decreased
    % % pi_star_diff_new = norm(pi_star.move - pi_star_new.move,'fro'); % how much increased/decreased
    % pi_star_diff_from_last = pi_star_diff_new - pi_star_diff; % how different is this from last one...
    % pi_star_diff = pi_star_diff_new;
    end
    
    % if t > max_iter; break; end
    k;
end

J_0 = J_new;
pi_star_0 = pi_star_new; 
    save("pi_star","pi_star")
    save("pi_star_0", "pi_star_0")
else
    load("pi_star","pi_star")
    load("pi_star_0", "pi_star_0")
end

%% Simulation
% Setup
% Control Law
pi_k = @(x,pi_star) pi_star(...
    X.pos.x==x.pos.x,...
    X.pos.y==x.pos.y,...
    X.pc.hp==x.pc.hp,...
    X.mn.hp==x.mn.hp);

% Intitial State
[x_0.pc.x, x_0.pc.y] = deal(1, 5); % x_pc_x and x_pc_y
[x_0.mn.x, x_0.mn.y] = deal(-2, 5); % x_mn_x and x_mn_y
x_0.pos.x = x_0.pc.x - x_0.mn.x; % relative x position
x_0.pos.y = x_0.pc.y - x_0.mn.y; % relative y position
x_0.pc.hp = const.pc.hp.max; % initial hp
x_0.mn.hp = const.mn.hp.max; % initial hp
x_0.pc.potion = 1;

% Initialization
rng(rng_seed);
x = x_0;
u = pi_k(x_0,pi_star_0);

for k = 1:simLength
    k,u
    w.pc.d4 = randi(4); w.pc.d6 = randi(6); w.pc.d8 = randi(8); w.pc.d20 = randi(20);
    w.mn.d4 = randi(4); w.mn.d6 = randi(6); w.mn.d8 = randi(8); w.mn.d20 = randi(20);
    % w = arrayfun(@(x) randi(x), D.diceRoll);
    [x, pc_hit, mn_hit] = DND_sys_update(x,u,w,const);
    u = pi_k(x,pi_star{k});
    X_sim(k) = x;
    if x.pc.hp <= 0; break; end
    if x.mn.hp <= 0; break; end
    U_sim(k) = u;
    W_sim(k) = w;
    pc_pf(k) = pc_hit
    mn_pf(k) = mn_hit
end


%% Plotting
close all
figure
for k = 1:length(X_sim)
    plot_DND_visualization(X_sim(k))
    ylim([0,10]);
    xlim([-4,4]);
    title("Round: ", num2str(k))
    pause(0.5)

    if X_sim(k).pc.hp <=0
        hold on
        x = get(gca,'XLim');
        y = get(gca,'YLim');
        text(min(x),mean(y),'Game Over!','FontSize',25,'Color','red','BackgroundColor','yellow')
        break
    elseif X_sim(k).mn.hp <= 0
        hold on
        x = get(gca,'XLim');
        y = get(gca,'YLim');
        text(min(x),mean(y),'Game Won!','FontSize',25,'Color','green','BackgroundColor','yellow')
        break
    end

    pause(1)
end



%% Extra functions
function pi_star = pi_star_from_idx(idx,size_Ju, U)
    [~,~,~,~,idx_move,idx_action] = ind2sub(size_Ju,idx);
    pi_star.move = U.move{idx_move};
    pi_star.action = U.action{idx_action};
end



