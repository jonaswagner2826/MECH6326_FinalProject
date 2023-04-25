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
x_new_pos = u.move([x.pos.x; x.pos.y]); % relative
if abs(x_new_pos(1)) <= const.relPosMax; x.pos.x = x_new_pos(1); end
if abs(x_new_pos(2)) <= const.relPosMax; x.pos.y = x_new_pos(2); end

% PC Action
switch u.action
    case const.action.melee
        "melee";
        if norm([x.pos.x;x.pos.y]) <= const.pc.melee.range
            x.mn.hp = (x.mn.hp' * M.pc.melee)';
        else
            x.pc.hp = 0*x.pc.hp; % not possible... don't do, you die
        end
    case const.action.ranged
        "ranged";
        if norm([x.pos.x;x.pos.y]) <= const.pc.ranged.range && (norm([x.pos.x;x.pos.y]) > const.pc.melee.range) 
            x.mn.hp = (x.mn.hp' * M.pc.ranged)';
        else
            x.pc.hp = 0*x.pc.hp; % not possible... don't do, you die
        end
    case const.action.heal
        "heal";
        M_update_heal = x.pc.potion(1)*M.pc.heal ...
            + x.pc.potion(2)*M.pc.nothing;
        x.pc.hp = (x.pc.hp'*M_update_heal)';
        x.pc.potion = [1;0];
    case const.action.nothing
        "nothing";
        x.pc.hp = (x.pc.hp' * M.pc.nothing)';
end

% Monster Movement
% x.mn.p = x.mn.p + round(normalize(x.pc.p-x.mn.p)); % absolute
x_new_pos = [x.pos.x;x.pos.y] + round(normalize([x.pos.x;x.pos.y])); % relative
if abs(x_new_pos(1)) <= const.relPosMax; x.pos.x = x_new_pos(1); end
if abs(x_new_pos(2)) <= const.relPosMax; x.pos.y = x_new_pos(2); end


% % static monster...
% x.pos = x.pos;

% Monster Action
% dist = norm(x.mn.p - x.pc.p, 1); % absolue
dist = norm([x.pos.x;x.pos.y]); % relative
if dist <= const.mn.melee.range
    x.pc.hp = (x.pc.hp'*M.mn.melee)';
elseif dist <= const.mn.ranged.range
    x.pc.hp = (x.pc.hp'*M.mn.ranged)';
else %nothing
    x.pc.hp = (x.pc.hp'*M.mn.nothing)';
end

x_new = x;

X.pos.x = -const.relPosMax:const.relPosMax; X.pos.y = X.pos.x;
x_new.idx.x = find(x_new.pos.x == X.pos.x);
x_new.idx.y = find(x_new.pos.x == X.pos.y);

% End of update
end