function plot_DND_visualization(x, u,const)
    %PLOT_DND_VISUALIZATION()
    %   plots a visualization of the current state of the DND system
    %   x = state w/
    %   x.pc.p = PC position
    %   x.pc.hp = PC Health
    %   x.mn.p = Monster position
    %   x.mn.hp = Monster Health
    %   u = input w/
    %   u.action = chosen action
    maxHealth = max(const.pc.hp.max,const.mn.hp.max);

    hold off
    ax = gca;

    % PC Location
    pc.loc = [x.pc.x + [-0.5 0.5]; x.pc.y + [1 -1]];
%     pc.img = imread('pc_img.png'); % Load image
    if u.action == "melee"
        pc.img = imread('visualization/pc_melee.png'); % Load image
    elseif u.action == "ranged"
        pc.img = imread('visualization/pc_ranged.png');
    elseif u.action == "heal"
        pc.img = imread('visualization/pc_heal.png');
    else
        pc.img = imread('visualization/pc_nothing.png');
    end

    image(pc.loc(1,:), pc.loc(2,:), pc.img); % Plot the image
    hold on
    grid on

    % Monster Image
    mn.loc = [x.mn.x + [-0.5 0.5]; x.mn.y + [1 -1]];
    mn.img = imread('visualization/dargon.png');
    image(mn.loc(1,:), mn.loc(2,:), mn.img); % Plot the image

    % PC Health
    pc.health = max(x.pc.hp/maxHealth,0);
    rectangle('Position', [pc.loc(1,2), pc.loc(2,2) 0.25, 2], 'FaceColor', 'k')
    rectangle('Position', [pc.loc(1,2), pc.loc(2,2) 0.25, 2*pc.health], 'FaceColor', 'g')

    % MN Health
    mn.health = max(x.mn.hp/maxHealth,0);
    rectangle('Position', [mn.loc(1,2), mn.loc(2,2) 0.25, 2], 'FaceColor', 'k')
    rectangle('Position', [mn.loc(1,2), mn.loc(2,2) 0.25, 2*mn.health], 'FaceColor', 'g')

    if pc.health == 0
        pc.img = imread("visualization/pc_dead.png");
    end

    if mn.health == 0
        mn.img = imread("visualization/dargon_dead.png");
    end
    
    set(ax,'XLimMode','auto','XDir','normal')
    set(ax,'YLimMode','auto','YDir','normal')


end