% Salt quantity comparison

%S_np = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','S');
%S_pert = ncread('/scratch/general/am8e13/results2_Salt36km/state.nc','S');
%S_blown = ncread('/scratch/general/am8e13/results2_blownup/state.nc','S');
S_blown = ncread('/scratch/general/am8e13/results2_blownupfull/state.nc','S');
%Z = ncread('grid.nc','Z');

T = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','T');
%T/(24*60*60)

dZ = zeros(size(Z));
dZ = Z(1:size(Z)-1) - Z(2:size(Z));
dZ(50)=dZ(49);

S_np_quant =  squeeze(sum(S_np,1));
S_np_quant =  squeeze(sum(S_np_quant,1));
S_np_quant_a = S_np_quant'*dZ;
plot(S_np_quant_a)

S_pert_quant =  squeeze(sum(S_pert,1));
S_pert_quant =  squeeze(sum(S_pert_quant,1));
S_pert_quant_a = S_pert_quant'*dZ;
hold on
plot(S_pert_quant_a,'r')

S_input = S_np;
S_input(36:40,69:81,36:42,:) = 100;
S_input_quant =  squeeze(sum(S_input,1));
S_input_quant =  squeeze(sum(S_input_quant,1));
S_input_quant_a = S_input_quant'*dZ;
plot(S_input_quant_a,'g')

S_blown_quant =  squeeze(sum(S_blown,1));
S_blown_quant =  squeeze(sum(S_blown_quant,1));
S_blown_quant_a = S_blown_quant'*dZ;
hold on
plot(S_blown_quant_a,'m')

legend('Normal','Desired Pert','Light Pert','Blownup Pert')

[aa,bb] = min(abs(S_input_quant_a - S_pert_quant_a(1:length(S_input_quant_a))))

(T(bb)-T(1))/(24*60*60)