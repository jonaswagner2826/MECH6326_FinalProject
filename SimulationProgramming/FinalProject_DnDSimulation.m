clear; close all; %clc;

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

% %Battlefield Set-Up
% battlefield_size = 50;
% grid = zeros(battlefield_size, battlefield_size); %create battlefield

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

%% Dynamic Programming
% Infinite Horizon, Value Iteration

% State Space
relPosMaxDist = 5;
X.pos.x = -relPosMaxDist:relPosMaxDist; X.pos.y = X.pos.x;
X.pc.hp = 0:hp_max; X.mn.hp = 0:hp_max;
[X.values{1}, X.values{2}, X.values{3}, X.values{4}] = ...
    ndgrid(X.pos.x, X.pos.y, X.pc.hp, X.mn.hp);

% Input Space
U.move = fieldnames(const.move);
U.action = fieldnames(const.action);

%% Probability Update Computation
recomputeP = false;
if recomputeP
    % Update Probabilities update computation
    hp_eye = eye(hp_max+1);
    P{length(U.move),length(U.action)} = [];
    for idx_move = 1:length(U.move); u.move = const.move.(U.move{idx_move});
        for idx_action = 1:length(U.action); u.action = const.action.(U.action{idx_action});
            for idx_x = 1:length(X.pos.x); x.pos.x = X.pos.x(idx_x);
                for idx_y = 1:length(X.pos.y); x.pos.y = X.pos.x(idx_y);
                    for idx_pc_hp = 1:length(X.pc.hp); x.pc.hp = hp_eye(:,idx_pc_hp);
                        for idx_mn_hp = 1:length(X.mn.hp); x.mn.hp = hp_eye(:,idx_mn_hp);
        % this creates the probability at all posible things...
        x_new = DND_markov_update(x,u,M,const);
        P{idx_move,idx_action}(idx_x,idx_y,idx_pc_hp,idx_mn_hp,:,:) = ...
            x_new.pc.hp*x_new.mn.hp';
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
pi_star.move = zeros(size(J)); pi_star.action = zeros(size(J));
J_new = ones(size(J));

% Stage Cost
g_k = @(pc_hp, mn_hp) -(pc_hp - mn_hp);
G_k = arrayfun(@(pc_hp, mn_hp) g_k(pc_hp, mn_hp), X.values{3}, X.values{4});
G_k(:,:,1,:) = 100; % Don't want to die...
G_k(:,:,:,1) = -100; % Want monster to die...
G_k([1 end],:,:,:) = 10*hp_max; % Don't run away
G_k(:,[1 end],:,:) = 10*hp_max; % Don't run away


% t = 0; %value iteration counter
% max_iter = 100;
N = 15; % Future Timesteps
pi_star_new = pi_star; clear pi_star; clear J; % for finite version
tic
J_diff = 0;
pi_star_diff = 0;
% while norm(J - J_new,'fro') >= 1e-6
for k = N:-1:0
    toc
    tic
    J{k+1} = J_new;
    pi_star{k+1} = pi_star_new;

    for idx_move = 1:length(U.move)
        u.move = const.move.(U.move{idx_move});
        for idx_action = 1:length(U.action)
            u.action = const.action.(U.action{idx_action});
            Ju(:,:,:,:,idx_move,idx_action) = G_k + sum( ...
                multiprod(P{idx_move,idx_action},J{k+1},[5 6],[3 4]),[5 6]);
            % multiprod(P{idx_move,idx_action},J,[5 6],[3 4]),[5 6]); % infinite version
        end
    end

    [J_new, pi_star_idx] = min(Ju,[],[5,6],"linear");
    [pi_star_new.move,p_star_new.action] = arrayfun(...
        @(idx) pi_star_from_idx(idx,size(Ju)), pi_star_idx);
    


    % t = t+1; % Count iterations
    J_diff_new = norm(J{k+1} - J_new,'fro'); % how much increased/decreased
    % J_diff_new = norm(J - J_new,'fro'); % how much increased/decreased
    J_diff_from_last = J_diff_new - J_diff; % how different is this from last one...
    J_diff = J_diff_new;

    pi_star_diff_new = norm(pi_star{k+1}.move - pi_star_new.move,'fro'); % how much increased/decreased
    % pi_star_diff_new = norm(pi_star.move - pi_star_new.move,'fro'); % how much increased/decreased
    pi_star_diff_from_last = pi_star_diff_new - pi_star_diff; % how different is this from last one...
    pi_star_diff = pi_star_diff_new;

    % if t > max_iter; break; end
end

J_0 = J_new;
pi_star_0 = pi_star_new; 







% % Terminal Cost
% g_N = @(pc_hp,mn_hp) pc_hp - mn_hp;
% G_N = arrayfun(@(pc_hp, mn_hp) g_N(pc_hp, mn_hp), X.values{3},X.values{4});

% Finite-time horrizon
% J = 
% for k = N:-1:0
%     J{k+1} = Jplus;
% hp_eye = eye(length(X.pc.hp));
%     for idx_x = 1:length(X.pos.x); x.pos.x = X.pos.x(idx_x);
%         for idx_y = 1:length(X.pos.y); x.pos.y = X.pos.y(idx_y);
%             for idx_pc_hp = 1:length(X.pc.hp)
%                 if X.pc.hp(idx_pc_hp) == 0 % If PC dies
%                     J_plus(idx_x,idx_y,:,:) = -100;
%                     continue
%                 end
%                 x.pc.hp = hp_eye(:,idx_pc_hp);
%                 for idx_mn_hp = 1:length(X.mn.hp)
%                     if X.mn.hp(idx_mn_hp) == 0 % If monster dies
%                         J_plus(idx_x,idx_y,:,:) = 100; 
%                     end
%                     x.mn.hp = hp_eye(:,idx_mn_hp);
%                     Ju = zeros(length(U.move), length(U.action)); % arbrirary
%                     for idx_move = 1:length(U.move)
%                         u.move = const.move.(U.move{idx_move});
%                         for idx_action = 1:length(U.action)
%                             u.action = const.action.(U.action{idx_action});
%                         x_new = DND_markov_update(x,u,M,const);
%             idx_x_new = find(X.pos.x == x_new.pos(1),1);
%             idx_y_new = find(X.pos.y == x_new.pos(2),1);
%             if any([isempty(idx_x_new), isempty(idx_y_new)]); continue; end %if moves too far away...
%     Ju(idx_move, idx_action) = G_k(idx_x,idx_y,idx_pc_hp,idx_mn_hp) + ...
%         sum((x_new.pc.hp*x_new.mn.hp').*J(idx_x_new, idx_y_new,:,:),'all'); %P( all new states ) * current J
%                         end
%                     end
%     [J(idx_x,idx_y,idx_pc_hp,idx_mn_hp), pi_idx] = max(Ju,[],"all"); % pi_star is weird... definetly can save as just index and then calculate later...
%     [idx_move_star,idx_action_star] = ind2sub(size(Ju),pi_idx);
%         pi_star{idx_x,idx_y,idx_pc_hp,idx_mn_hp} = {...
%             U.move{idx_move_star};
%             U.action{idx_action_star}};
%                 end
%             end
%         end
%     end
% end



% % (the following is the code for attempting with infinite horrizon)
% t = 0;
% max_iter = 10;
% %value iteration counter
% tic
% diff = 0;
% while norm(J - J_plus,'fro') >= 1e-6
%     toc
%     tic
%     J = J_plus;
%     hp_eye = eye(length(X.pc.hp));
%     for idx_x = 1:length(X.pos.x); x.pos.x = X.pos.x(idx_x);
%         for idx_y = 1:length(X.pos.y); x.pos.y = X.pos.y(idx_y);
%             for idx_pc_hp = 1:length(X.pc.hp)
%                 if X.pc.hp(idx_pc_hp) == 0 % If PC dies
%                     J_plus(idx_x,idx_y,:,:) = -100;
%                     continue
%                 end
%                 x.pc.hp = hp_eye(:,idx_pc_hp);
%                 for idx_mn_hp = 1:length(X.mn.hp)
%                     if X.mn.hp(idx_mn_hp) == 0 % If monster dies
%                         J_plus(idx_x,idx_y,:,:) = 100;
%                         continue;
%                     end
%                     x.mn.hp = hp_eye(:,idx_mn_hp);
%                     Ju = zeros(length(U.move), length(U.action));
%                     for idx_move = 1:length(U.move)
%                         u.move = const.move.(U.move{idx_move});
%                         for idx_action = 1:length(U.action)
%                             u.action = const.action.(U.action{idx_action});
%                         x_new = DND_markov_update(x,u,M,const);
%             idx_x_new = find(X.pos.x == x_new.pos(1),1);
%             idx_y_new = find(X.pos.y == x_new.pos(2),1);
%             if any([isempty(idx_x_new), isempty(idx_y_new)]); Ju(idx_move,idx_action) = 100; continue; end %if moves too far away...
%     Ju(idx_move, idx_action) = G_k(idx_x,idx_y,idx_pc_hp,idx_mn_hp) + ...
%         sum((x_new.pc.hp*x_new.mn.hp').*J(idx_x_new, idx_y_new,:,:),'all'); %P( all new states ) * current J
%                         end
%                     end
%             if t >= 2; 
%                 x_new.pos
%                 Ju
%                 t = t;
%                 % idx_x = 
%             end
%     [J_plus(idx_x,idx_y,idx_pc_hp,idx_mn_hp), pi_idx] = min(Ju,[],"all"); % pi_star is weird... definetly can save as just index and then calculate later...
%     [idx_move_star,idx_action_star] = ind2sub(size(Ju),pi_idx);
%         pi_star{idx_x,idx_y,idx_pc_hp,idx_mn_hp} = {...
%             U.move{idx_move_star};
%             U.action{idx_action_star}};
%                 end
%             end
%         end
%     end
%     t = t+1 % Count iterations
%     diff_new = norm(J - J_plus,'fro') % how much increased/decreased
%     diff_from_last = diff_new - diff % how different is this from last one...
%     diff = diff_new;
%     if t > max_iter; break; end
% end





function [idx_move,idx_action] = pi_star_from_idx(ind,size_Ju)
    [~,~,~,~,idx_move,idx_action] = ind2sub(size_Ju,ind);
    pi_star = [idx_move;idx_action];
end


