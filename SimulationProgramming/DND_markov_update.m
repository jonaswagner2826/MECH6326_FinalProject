function x_new = DND_markov_update(x, u, M, const)
    
% % state as a vector 
% x.pos = x_in(1:2,:);
% x.pc.hp = x_in(3,:);
% x.mn.hp = x_in(4,:);
% % input is a single input
% u.move = u_in{1};
% u.action = u_in{2};

% PC Position
% x.pc.p = u.move(x.pc.p); % absolute
x.pos = u.move([x.pos.x; x.pos.y]); % relative

% PC Action
switch u.action
    case const.action.melee
        "melee";
        if norm(x.pos) <= const.pc.melee.range
            x.mn.hp = (x.mn.hp' * M.pc.melee)';
        end
    case const.action.ranged
        "ranged";
        if norm(x.pos) <= const.pc.ranged.range
            x.mn.hp = (x.mn.hp' * M.pc.ranged)';
        end
    case const.action.heal
        "heal";
        x.pc.hp = (x.pc.hp' * M.pc.heal)';
    case const.action.nothing
        "nothing";
        x.pc.hp = (x.pc.hp' * M.pc.nothing)';
end

% Monster Movement
% x.mn.p = x.mn.p + round(normalize(x.pc.p-x.mn.p)); % absolute
x.pos = x.pos + round(normalize(x.pos)); % relative

% % static monster...
% x.pos = x.pos;

% Monster Action
% dist = norm(x.mn.p - x.pc.p, 1); % absolue
dist = norm(x.pos); % relative
if dist <= const.mn.melee.range
    x.pc.hp = (x.pc.hp'*M.mn.melee)';
elseif dist <= const.mn.ranged.range
    x.pc.hp = (x.pc.hp'*M.mn.ranged)';
else %nothing
    x.pc.hp = (x.pc.hp'*M.mn.nothing)';
end

x_new = x;
% x_new(1:2) = x.pos;
% x_new(3) = x.pc.hp;
% x_new(4) = x.mn.hp;

% End of update
end