x_pc_p = [0,0];
x_mn_p = [5,15];

for i = 1:15
    x_mn_p = x_mn_p + round(normalize(x_pc_p - x_mn_p))
end