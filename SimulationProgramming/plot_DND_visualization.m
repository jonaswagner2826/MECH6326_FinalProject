function plot_DND_visualization(x)
    %PLOT_DND_VISUALIZATION()
    %   plots a visualization of the current state of the DND system
    %   x = state w/
    %   x.pc.p = PC position
    %   x.pc.hp = PC Health
    %   x.mn.p = Monster position
    %   x.mn.hp = Monster Health

    maxHealth = 15;

    hold off
    ax = gca;

    % PC Location
    pc.loc = [x.pc.p(1) + [-0.5 0.5]; x.pc.p(2) + [1 -1]];
%     pc.img = imread('pc_img.png'); % Load image
    pc.img = imread('pc.png'); % Load image
    image(pc.loc(1,:), pc.loc(2,:), pc.img); % Plot the image
    hold on
    grid on

    % Monster Image
    mn.loc = [x.mn.p(1) + [-0.5 0.5]; x.mn.p(2) + [1 -1]];
%     mn.img = imread('mn_img.png');
    mn.img = imread('dargon.png');
    image(mn.loc(1,:), mn.loc(2,:), mn.img); % Plot the image


    
    % PC Health
    pc.health = x.pc.hp/maxHealth;
    rectangle('Position', [pc.loc(1,2), pc.loc(2,2) 0.25, 2], 'FaceColor', 'k')
    rectangle('Position', [pc.loc(1,2), pc.loc(2,2) 0.25, 2*pc.health], 'FaceColor', 'g')
    % MN Health
    mn.health = x.mn.hp/maxHealth;
    rectangle('Position', [mn.loc(1,2), mn.loc(2,2) 0.25, 2], 'FaceColor', 'k')
    rectangle('Position', [mn.loc(1,2), mn.loc(2,2) 0.25, 2*mn.health], 'FaceColor', 'g')
    
% %     hold on
    set(ax,'XLimMode','auto','XDir','normal')
    set(ax,'YLimMode','auto','YDir','normal')

%     pc.ax = axes('Position', [0.7 0.7 1 1])%[pc.loc(1,2) pc.loc(2,2) 1 1])
%     %     ;%, 'Visible','off');
%     bar(pc.ax, x.pc.hp, 'FaceColor','g','EdgeColor','none')
%     ylim(pc.ax, [0 maxHealth])

end