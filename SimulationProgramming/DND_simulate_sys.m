function results = DND_simulate_sys(x_0, pi_k, pi_star_0, const, pi_star)

    x = x_0;
    % x.pos saturation
    x.pos.x = min(max(x.pc.x - x.mn.x,-const.relPosMax),const.relPosMax);
    x.pos.y = min(max(x.pc.y - x.mn.y,-const.relPosMax),const.relPosMax);
    u = pi_k(x,pi_star_0);

    for k = 1:const.finiteHorrizon
        % k,u
        w.pc.d4 = randi(4); w.pc.d6 = randi(6); w.pc.d8 = randi(8); w.pc.d20 = randi(20);
        w.mn.d4 = randi(4); w.mn.d6 = randi(6); w.mn.d8 = randi(8); w.mn.d20 = randi(20);
        [x, pc_hit, mn_hit] = DND_sys_update(x,u,w,const);

        % x.pos is saturation
        x.pos.x = min(max(x.pc.x - x.mn.x,-const.relPosMax),const.relPosMax);
        x.pos.y = min(max(x.pc.y - x.mn.y,-const.relPosMax),const.relPosMax);

        u = pi_k(x,pi_star{k});
        % u = pi_k(x,pi_star_0); % infinite horrizon atteempt
        results.X(k) = x;
        if x.pc.hp <= 0; break; end
        if x.mn.hp <= 0; break; end
        results.U(k) = u;
        results.W(k) = w;
        results.pc_sf(k) = pc_hit;
        results.mn_sf(k) = mn_hit;
    end
end