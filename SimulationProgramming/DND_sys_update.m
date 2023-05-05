function [x_new, pc_sf, mn_sf] = DND_sys_update(x,u,w,const)
    %DND_sys_update updates the system acording to system dynamics

    % New values
    x_new = x;
    % Player Movement
    % x_new(pc_p) = x_new(pc_p) + u(pc_m);
    pc_move = const.move.(u.move);
    x_new_pos = pc_move([x.pc.x;x.pc.y]);
    if x_new_pos(1) ~= x.mn.x; x_new.pc.x = x_new_pos(1); end
    if x_new_pos(2) ~= x.mn.y; x_new.pc.y = x_new_pos(2); end
    
    % Player Action
    pc_sf = 0;
    mn_sf = 0;
    % Melee
    if u.action == "melee" && ...
            norm([x_new.pc.x - x_new.mn.x; ...
                x_new.pc.y - x_new.mn.y],2) <= const.pc.melee.range
        % if const.pc.strength + w(pc_d20) >= const.mn.ac && w(pc_d20) ~= 1
        if const.pc.strength + w.pc.d20 >= const.mn.ac && w.pc.d20 ~= 1
            pc_sf = 1;
        elseif w.pc.d20 == 20
            pc_sf = 1;
        end
        % Melee Damage
        % x_new(mn_hp) = x_new(mn_hp) - pc_sf*(const.pc.melee.weapon + w(pc_d8));
        x_new.mn.hp = x_new.mn.hp - pc_sf*(const.pc.melee.weapon + w.pc.d8);
    
        % Ranged
    elseif u.action == "ranged" && ...
            norm([x_new.pc.x - x_new.mn.x; ...
                x_new.pc.y - x_new.mn.y],2) <= const.pc.ranged.range && (norm([x_new.pc.x - x_new.mn.x; ...
                x_new.pc.y - x_new.mn.y],2) > const.pc.melee.range)
        if const.pc.dext + w.pc.d20 >= const.mn.ac && w.pc.d20 ~= 1
            pc_sf = 1;
        elseif w.pc.d20 == 20
            pc_sf = 1;
        end
        % Melee Damage
        % x_new(mn_hp) = x_new(mn_hp) - pc_sf*(const.pc.melee.weapon + w(pc_d8));
        x_new.mn.hp = x_new.mn.hp - pc_sf*(const.pc.ranged.weapon + w.pc.d8);

    % Heal
    elseif u.action == "heal" && x_new.pc.potion >= 1
        x_new.pc.hp = min(...
            x_new.pc.hp + const.pc.heal.baseheal + w.pc.d4,...
            const.pc.hp.max);
        x_new.pc.potion = x_new.pc.potion - 1;

    % Nothing
    end

    % Monster Dies
    x_new.mn.x = max(min(x_new.mn.x,x_new.pc.x + const.relPosMax), ...
        x_new.pc.x - const.relPosMax);
    x_new.mn.y = max(min(x_new.mn.y,x_new.pc.y + const.relPosMax), ...
        x_new.pc.y - const.relPosMax);
    x_new.mn.hp = max(x_new.mn.hp,0);
    if x_new.mn.hp == 0; return; end 

    % Monster Movement
    mn_m = round(normalize([x_new.pc.x - x_new.mn.x; ...
                x_new.pc.y - x_new.mn.y])); % direction
    mn_new_pos = [x.mn.x; x.mn.y] + mn_m;
    if mn_new_pos(1) ~= x_new.pc.x; x_new.mn.x = mn_new_pos(1); end
    if mn_new_pos(2) ~= x_new.pc.y; x_new.mn.y = mn_new_pos(2); end

    % static monster:
    % x_new.mn.x = x.mn.x; x_new.mn.y = x.mn.y;

    % Monster Action
    mn_sf = 0;
    % Melee
    if norm([x_new.mn.x - x_new.pc.x; ...
                x_new.mn.y - x_new.pc.y],1) <= const.mn.melee.range
        if const.mn.strength + w.mn.d20 >= const.pc.ac && w.mn.d20 ~= 1
            mn_sf = 1;
        elseif w.mn.d20 == 20
            mn_sf = 1;
        end
        % Melee Damage
        x_new.pc.hp = x_new.pc.hp - mn_sf*(const.mn.melee.weapon + w.mn.d8);
    % Ranged
    elseif norm([x_new.mn.x - x_new.pc.x; ...
                x_new.mn.y - x_new.pc.y],1) <= const.mn.ranged.range
        % if const.pc.strength + w(pc_d20) >= const.mn.ac && w(pc_d20) ~= 1
        if const.mn.dext + w.mn.d20 >= const.pc.ac && w.mn.d20 ~= 1
            mn_sf = 1;
        elseif w.mn.d20 == 20
            mn_sf = 1;
        end
        % Melee Damage
        x_new.pc.hp = x_new.pc.hp - mn_sf*(const.mn.ranged.weapon + w.mn.d8);
       
    % Heal
    % Nothing
    end
    x_new.pc.hp = max(x_new.pc.hp,0); % PC dies
end