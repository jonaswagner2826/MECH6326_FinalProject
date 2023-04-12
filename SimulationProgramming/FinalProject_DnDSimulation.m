clear all; close all; %clc;

%% MECH 6326 Final Project: D&D Combat Simulation
% Alyssa Vellucci: AMV170001
% Jonas Wagner: JRW200000

%% System Parameters
const.pc.melee.range = 1;
const.pc.melee.weapon = 1;
const.pc.melee.d = 6;
const.pc.ranged.range = 3;
const.pc.ranged.weapon = 2;
const.pc.ranged.d = 8;
const.pc.speed = 1;
const.pc.ac = 15;
const.pc.strength = 5;
const.pc.dext = 5;
const.mn = const.pc; % same stats
const.pc.heal.baseheal = 1;
const.pc.heal.d = 4;

%Battlefield Set-Up
battlefield_size = 50;
grid = zeros(battlefield_size, battlefield_size); %create battlefield

%% Markov Chain Definitions
% Move 
const.move.N = @(x) x + [0;1];
const.move.E = @(x) x + [1;0];
const.move.S = @(x) x + [0;-1];
const.move.W = @(x) x + [-1;0];
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

% Actions
hp_max = 10;
hp_states = 0:hp_max;
num_hp_states = length(hp_states);
% PC
% Melee
% M.pc.melee.w_sf = @(w_d20) any([
%     all([const.pc.strength + w_d20 >= const.mn.ac, w_d20 ~= 1],2), ...
%         w_d20 == 20],2);
% M.pc.melee.damage = @(w_d20,w_d6) const.pc.melee.weapon + ...
%     M.pc.melee.w_sf(w_d20)*w_d6';
% M.pc.melee.markov = zeros(num_hp_states);

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
% M.pc.ranged.w_sf = @(w_d20) any([
%     all([const.pc.dext + w_d20 >= const.mn.ac, w_d20 ~= 1],2),...
%         w_d20 == 20],2);
% M.pc.ranged.damage = @(w_d20,w_d6) const.pc.ranged.weapon + ...
%     const.pc.ranged.w_sf(w_d20)*w_d8;
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
        if i > num_hp_states; i = num_hp_states;end
        M.pc.heal(i,j) = M.pc.heal(i,j) + (1/const.pc.heal.d);
    end
end
M.pc.heal = M.pc.heal';

% Nothing
M.pc.nothing = eye(num_hp_states);

% Monster
M.mn = M.pc; % same attack assumption (could redefine to be different)
M.mn.heal = M.pc.nothing; % Heal not possible


%% Markov System Update
% single timestep update setup given the state and input... example
% does not allow for the position to be updated independently given value
% of hp currently (although this is posisble if a finite play space is
% imlimented and a markov chain for movement is defined)
% 
% % Initialization
% % Position States
% x.pc.p = [5;-6];
% x.mn.p = [4;-10];
% 
% % HP States
% x_0.pc.hp = 10;
% x_0.mn.hp = 15;
% x.pc.hp = zeros(num_hp_states,1); x.pc.hp(x_0.pc.hp+1) = 1;
% x.mn.hp = zeros(num_hp_states,1); x.mn.hp(x_0.mn.hp+1) = 1;
% 
% % Markov Implimentation
% u.action = const.action.melee;
% u.move = const.move.N; 

% DND_markov_update(x, u, M, const);

%% Dynamic Programming
% Infinite Horizon, Value Iteration


% State Space
relPosMaxDist = 3;
X.pos.x = -relPosMaxDist:relPosMaxDist; X.pos.y = X.pos.x;
X.pc.hp = 0:hp_max; X.mn.hp = 0:hp_max;
[X.values{1}, X.values{2}, X.values{3}, X.values{4}] = ...
    ndgrid(X.pos.x, X.pos.y, X.pc.hp, X.mn.hp);

% Input Space
U.move = fieldnames(const.move);
U.action = fieldnames(const.action);

% Probabilites from update
hp_eye = eye(length(X.pc.hp));
for idx_move = 1:length(U.move); u.move = const.move.(U.move{idx_move});
    for idx_action = 1:length(U.action); u.action = const.action.(U.action{idx_action});
        for idx_x = 1:length(X.pos.x); x.pos.x = X.pos.x(idx_x);
            for idx_y = 1:length(X.pos.y); x.pos.y = X.pos.y(idx_y);
                for idx_pc_hp = 1:length(X.pc.hp)
                    x.pc.hp = hp_eye(:,idx_pc_hp);
%                     x.pc.hp = zeros(length(X.pc.hp),1);
%                     x.pc.hp(idx_pc_hp) = 1;
                    for idx_mn_hp = 1:length(X.mn.hp)
                        x.mn.hp = hp_eye(:,idx_mn_hp);
%                         x.mn.hp = zeros(length(X.mn.hp),1);
%                         x.mn.hp(idx_mn_hp) = 1;
                        x_new = DND_markov_update(x,u,M,const);
P.pc.hp{idx_move,idx_action}(idx_x,idx_y,idx_pc_hp,idx_mn_hp,:) = ...
    x_new.pc.hp;
P.mn.hp{idx_move,idx_action}(idx_x,idx_y,idx_pc_hp,idx_mn_hp,:) = ...
    x_new.mn.hp;
                    end
                end
            end
        end
    end
end

% Initialize optimal costs, policies
J = zeros(size(X.values(:,:,:,:,1)));%length(X.pos.x),length(X.pos.y),length(X.hp.pc),length(X.hp.mn));
pi_star = J; %?
J_plus = ones(size(J));

% Stage Cost
g_k = @(pc_hp, mn_hp) pc_hp - mn_hp;%x.pc.hp - x.mn.hp;
G_k = arrayfun(@(pc_hp, mn_hp) g_k(pc_hp, mn_hp), X.values{3},X.values{4});
% G = zeros(size(G))

t = 0;
max_iter = 500;
%value iteration counter
while pagenorm(J - J_plus) >= 1e-6
    t = t+1; % Count iterations
    J = J_plus;
    if t > max_iter; break; end
%     Ju{length(U.move),length(U.action)};
    for idx_pos_x = 1:length(X.pos.x)
        for idx_pos_y = 1:length(X.pos.y)
%             for idx_hp_pc = 1:length(X.hp.pc)
%                 for idx_hp_mn = 1:length(X.hp.mn)
                    for idx_move = 1:length(U.move)
                        for idx_action = 1:length(U.action)
%                             Ju{idx_move, idx_action} = G_k + ...
                        end
                    end
                    % TODO: follow the procedure outlined in other things
                    % (mainly a version of L13 and L14) 
                    % that determines the best selection of u... 
        end
%             end
%         end
    end
end

% 
% J.move = zeros(battlefield_size, battlefield_size);
% pi_star.move = J.move;
% J_plus.move = ones(battlefield_size,battlefield_size);
% 
% t = 0; %value iteration counter
% 
% while norm(J.move - J_plus.move) >= 1e-6
%     t = t+1;
%     J.move = J_plus.move;
%     for i = 1:battlefield_size
%         for j = 1:battlefield_size
%             %update PC movement
%             
%         end 
%     end
% end










