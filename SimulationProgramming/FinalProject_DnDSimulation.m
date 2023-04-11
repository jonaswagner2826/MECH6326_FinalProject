clear all; close all; %clc;

%% MECH 6326 Final Project: D&D Combat Simulation
% Alyssa Vellucci: AMV170001
% Jonas Wagner: JRW200000

%% Problem Definition
melee = 1;
ranged = 2;
% nothing = 3;
% heal = 4;
heal = 3;
nothing = 4; % switched to match the theory doc

% Monster Set-Up
m_act = [melee ranged nothing]; %actions monster can perform on its turn
m_HPtot = 100; %monster hit point total
m_HP = [0:1:m_HPtot]; %monster state vector

%PC Set-Up
pc_act = [melee ranged nothing heal]; %actions player character can perform on its turn
pc_HPtot = m_HPtot; %player hit point total
pc_HP = [0:1:pc_HPtot]; %pc state vector

%Movement Inputs
moveset.left = [-1 0]; moveset.right = [1,0]; moveset.up = [0 1]; moveset.down = [0 -1];
moveset.upleft = [-1 1]; moveset.upright = [1 1]; moveset.downleft = [-1 -1]; moveset.downright = [1 -1];

% left = [-1 0]; right = [1,0]; up = [0 1]; down = [0 -1];
% upleft = [-1 1]; upright = [1 1]; downleft = [-1 -1]; downright = [1 -1];

%moveset = {left, right, up, down, upleft, upright, downleft, downright};

%Battlefield Set-Up
battlefield_size = 1000;
grid = zeros(battlefield_size, battlefield_size); %create battlefield

%Potion Set-Up
potion = [1 0]; %to check if potion is available

%Dice Roll Set-Up
d2 = [0.5 0.5];
d4 = [0.25 0.25 0.25 0.25];
d6 = [1/6 1/6 1/6 1/6 1/6 1/6];
d8 = [1/8 1/8 1/8 1/8 1/8 1/8 1/8 1/8];
d10 = [0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1];
d20 = zeros(1,20);
d100 = zeros(1,100);
for i = 1:20
    d20(i) = 1/20;
end
for i = 1:100
    d100(i) = 1/100;
end
dice = {d2 d4 d6 d8 d10 d20 d100}; 



%% System Parameters
const.pc.melee.range = 1;
const.pc.melee.weapon = 2;
const.pc.melee.d = 6;
const.pc.ranged.range = 5;
const.pc.ranged.weapon = 2;
const.pc.ranged.d = 8;
const.pc.speed = 1;
const.pc.ac = 15;
const.pc.strength = 5;
const.pc.dext = 5;
const.mn = const.pc; % same stats
const.pc.heal.baseheal = 1;
const.pc.heal.d = 4;


%% Markov Chain Definitions
% Move 
move.N = @(x) x + [0;1];
move.E = @(x) x + [1;0];
move.S = @(x) x + [0;-1];
move.W = @(x) x + [-1;0];
move.NE = @(x) x + [1;1];
move.NW = @(x) x + [-1;1];
move.SE = @(x) x + [1;1];
move.SW = @(x) x + [1;-1];

% Action
action.melee = 1;
action.ranged = 2;
action.heal = 3;
action.nothing = 4;

% Dice (not really used)
% D.d2 = (1/2)*ones(2,1);
D.d4 = (1/4)*ones(4,1);
D.d6 = (1/6)*ones(6,1);
D.d8 = (1/8)*ones(8,1);
% D.d10 = (1/10)*ones(10,1);
D.d20 = (1/20)*ones(20,1);
% D.d100 = (1/100)*ones(100,1);

% Actions
hp_max = 15;
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
for j = 1:num_hp_states
    for d = 1:const.pc.heal.d
        i = j + const.pc.heal.baseheal + d;
        if i > num_hp_states; i = num_hp_states;end
        M.pc.heal(i,j) = M.pc.heal(i,j) + (1/const.pc.heal.d);
    end
end

% Nothing
M.pc.nothing.markov = eye(num_hp_states);

% Monster
M.mn = M.pc; % same attack assumption (could redefine to be different)
M.mn.heal = M.pc.nothing; % Heal not possible


%% Markov System Update
% single timestep update setup given the state and input... example
% does not allow for the position to be updated independently given value
% of hp currently (although this is posisble if a finite play space is
% imlimented and a markov chain for movement is defined)

% Initialization
% Position States
x.pc.p = [5;-6];
x.mn.p = [4;-10];

% HP States
x_0.pc.hp = 10;
x_0.mn.hp = 15;
x.pc.hp = zeros(num_hp_states,1); x.pc.hp(x_0.pc.hp+1) = 1;
x.mn.hp = zeros(num_hp_states,1); x.mn.hp(x_0.mn.hp+1) = 1;

% Markov Implimentation
u.action = action.melee;
u.move = move.N; 

% PC Position
x.pc.p = u.move(x.pc.p);

% PC Action
switch u.action
    case action.melee
        "melee"
        x.mn.hp = x.mn.hp' * M.pc.melee;
    case action.ranged
        "ranged"
        x.mn.hp = x.mn.hp' * M.pc.ranged;
    case action.heal
        "heal"
        x.pc.hp = x.pc.hp' * M.pc.heal;
    case action.nothing
        "nothing"
%         x.pc.hp = x.pc.hp' * M.pc.nothing;
end

% Monster Movement
x.mn.p = x.mn.p + round(normalize(x.pc.p-x.mn.p));

% Monster Action
dist = norm(x.mn.p - x.pc.p, 1);
if dist <= const.mn.melee.range
    x.pc.hp = x.pc.hp'*M.mn.melee;
elseif dist <= const.mn.ranged.range
    x.pc.hp = x.pc.hp'*M.mn.ranged;
else %nothing
end

% End of update














