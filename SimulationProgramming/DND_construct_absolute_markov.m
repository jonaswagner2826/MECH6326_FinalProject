function P = DND_construct_absolute_markov(hp_max, X, U, const, M)
    tic
    % Update Probabilities update computation
    hp_eye = eye(hp_max+1);
    potion_eye = eye(2);
    % P{length(U.move),length(U.action)} = [];
    P{length(U.move),length(U.action)} = {};
    tic
    for idx_move = 1:length(U.move); u.move = const.move.(U.move{idx_move});
        for idx_action = 1:length(U.action); u.action = const.action.(U.action{idx_action});

            idx_move, idx_action, toc, tic
            
                P{idx_move,idx_action}{...
                    X.size(1), X.size(2), X.size(3), X.size(4), X.size(5)} = [];
        
            for idx_x = 1:length(X.pos.x); x.pos.x = X.pos.x(idx_x);
                for idx_y = 1:length(X.pos.y); x.pos.y = X.pos.x(idx_y);
                    for idx_pc_hp = 1:length(X.pc.hp); x.pc.hp = hp_eye(:,idx_pc_hp);
                        for idx_mn_hp = 1:length(X.mn.hp); x.mn.hp = hp_eye(:,idx_mn_hp);
                            for idx_potion = 1:length(X.pc.potion); x.pc.potion = potion_eye(:,idx_potion);
        x_new = DND_markov_update(x,u,M,const);
    
        P_temp = zeros(prod(X.size),1);
        P_temp(sub2ind(...
            X.size,x_new.idx.x,x_new.idx.y,1,1)+(1:prod(X.size(3:4)))) = ...
            x_new.pc.hp*x_new.mn.hp';
        P{idx_move,idx_action}{idx_x,idx_y,idx_pc_hp,idx_mn_hp,idx_potion} = sparse(P_temp);
                            end
                        end
                    end
                end
            end
        end
    end
end