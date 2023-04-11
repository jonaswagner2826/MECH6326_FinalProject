function [x_new] = DND_sys_update(x,u,w,const)
    %DND_sys_update updates the system acording to system dynamics
    arguments
        x (7,1) %State [x_pc_p, x_mn_p, x_pc_hp, x_mn_hp, x_pc_potion]^T
        u (3,1) %PC Inputs [u_pc_m, u_pc_a]^T
                % u_pc_m \in \Z^2 ... u_pc_a \in action:
                % melee = 1, ranged = 2, health = 3, nothing = 4
        w (8,1) %Dice Rolls [w_pc_d4,w_pc_d6,w_pc_d8,w_pc_d20,
                % w_mn_d4,w_mn_d6,w_mn_d8,w_mn_d20]^T - not all used
        const = {}
    end
    if isempty(const)
        const.pc.melee.range = 1;
        const.pc.melee.weapon = 2;
        const.pc.ranged.range = 5;
        const.pc.ranged.weapon = 2;
        const.pc.speed = 1;
        const.pc.ac = 15;
        const.pc.strength = 5;
        const.pc.dext = 5;
        const.mn = const.pc; % same stats
        const.potion.baseheal = 1;
    end

    % Indexes
    pc_p = 1:2; mn_p = 3:4; 
    pc_hp = 5; mn_hp = 6; pc_potion = 7;
    pc_m = 1:2; pc_a = 3;
    pc_d4 = 1; pc_d6 = 2; pc_d8 = 3; pc_d20 = 4;
    mn_d4 = 5; mn_d6 = 6; mn_d8 = 7; mn_d20 = 8;

    % New values
    x_new = x;
    % Player Movement
    x_new(pc_p) = x_new(pc_p) + u(pc_m);

    % Player Action
    pc_sf = 0;
    % Melee
    if u(pc_a) == 1 && norm(x_new(pc_p) - x_new(mn_p),1) <= const.pc.melee.range
        if const.pc.strength + w(pc_d20) >= const.mn.ac && w(pc_d20) ~= 1
            pc_sf = 1;
        elseif w(pc_d20) == 20
            pc_sf = 1;
        end
        % Melee Damage
        x_new(mn_hp) = x_new(mn_hp) - pc_sf*(const.pc.melee.weapon + w(pc_d8));
    % Ranged
    elseif u_pc_a == 2 && norm(x_new(pc_p) - x_new(mn_p),1) <= const.pc.ranged.range
        if const.pc.dext + w(pc_d20) >= const.mn.ac && w(pc_d20) ~= 1
            pc_sf = 1; 
        elseif w(pc_d20) == 20
            pc_sf = 1;
        end
        % Ranged Damage
        x_new(mn_hp) = x_new(mn_hp) - pc_sf*(const.pc.ranged.weapon + w(pc_d6)); 
    % Heal
    elseif u_pc_a == 3 && x_new(pc_potion) >= 1
        x_new(pc_hp) = x_new(pc_hp) + const.potion.baseheal + w(pc_d4);
        x_new(pc_potion) = x_new(pc_potion) - 1;
    % Nothing
    end

    % Monster Movement
    mn_m = round(normalize(x_new(pc_p) - x_new(mn_p))); % direction
    x_new(mn_p) = x_new(mn_p) + mn_m;

    % Monster Action
    mn_sf = 0;
    % Melee
    if norm(x_new(mn_p) - x_new(pc_p),1) <= const.mn.melee.range
        if const.mn.strength + w(mn_d20) >= const.pc.ac && w(mn_d20) ~= 1
            mn_sf = 1;
        elseif w(pc_d20) == 20
            mn_sf = 1;
        end
        x_new(pc_hp) = x_new(pc_hp) - mn_sf*(const.mn.melee.weapon + w(mn_d8)); % Melee Damage
    % Ranged
    elseif norm(x_new(mn_p) - x_new(pc_p),1) <= const.mn.ranged.range
        if const.mn.dext + w(mn_d20) >= const.pc.ac && w(mn_d20) ~= 1
            mn_sf = 1; 
        elseif w(mn_d20) == 20
            mn_sf = 1;
        end
        x_new(pc_hp) = x_new(pc_hp) - mn_sf*(const.mn.ranged.weapon + w(mn_d6)); % Ranged Damage
    % Heal
    % Nothing
    end

end