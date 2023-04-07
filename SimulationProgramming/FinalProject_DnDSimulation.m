clear all; close all; clc;

%% MECH 6326 Final Project: D&D Combat Simulation
% Alyssa Vellucci: AMV170001
% Jonas Wagner: JRW200000

%% Problem Definition
melee = 1;
ranged = 2;
nothing = 3;
heal = 4;

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









