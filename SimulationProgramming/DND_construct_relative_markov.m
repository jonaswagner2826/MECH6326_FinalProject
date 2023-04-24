function M = DND_construct_relative_markov(num_hp_states, const)
    % PC ----------------------------------------------
    % Melee
    M.pc.melee = single_M_calc(num_hp_states, ...
        const.pc.strength-const.mn.ac, ...
        const.pc.melee.weapon,...
        const.pc.melee.d);

    % Ranged
    M.pc.ranged = single_M_calc(num_hp_states, ...
        const.pc.dext - const.mn.ac,...
        const.pc.ranged.weapon,...
        const.pc.ranged.d);

    % Heal
    M.pc.heal = zeros(num_hp_states);
    M.pc.heal(1,1) = 1;
    for i = 2:num_hp_states
        for d = 1:const.pc.heal.d
            j = i + const.pc.heal.baseheal + d;
            if j > num_hp_states; j = num_hp_states; end
            M.pc.heal(i,j) = M.pc.heal(i,j) + (1/const.pc.heal.d);
        end
    end

    % Nothing
    M.pc.nothing = eye(num_hp_states);


    % Monster --------------------------------------
    % Melee
    M.mn.melee = single_M_calc(num_hp_states, ...
        const.mn.strength-const.pc.ac, ...
        const.mn.melee.weapon,...
        const.mn.melee.d);

    % Ranged
    M.mn.ranged = single_M_calc(num_hp_states, ...
        const.mn.dext - const.pc.ac,...
        const.mn.ranged.weapon,...
        const.mn.ranged.d);

    % Nothing
    M.mn.nothing = eye(num_hp_states);
end



function M = single_M_calc(num_hp_states, sf_modifier, hp_modifier, size_dice)
    M = zeros(num_hp_states);
    P_s = (20 + sf_modifier)/20 + 1/20 - 1/20;
    P_sf = [P_s, 1-P_s];
    for i = 1:num_hp_states
        M(i,i) = P_sf(1);
        for d = 1:size_dice % loop through dice rolls
            j = i - hp_modifier - d;
            if j < 1; j = 1;end %zero out any negative states
            M(i,j) = M(i,j) + P_sf(2)/size_dice;
        end
    end
end