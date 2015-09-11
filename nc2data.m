% Writing .data files from .nc files
function [iter] = nc2data(n)

%ieee='b';
ieee='ieee-le';
prec='real*8';

state = rdmnc('state.*','U','V','W','iter') ;

for i = 1 : n

n_iter = strcat(num2str(zeros(1,10-length(num2str(state.iter(i)))),'%1d'),num2str(state.iter(i)));

fid=fopen(strcat('VVEL.',n_iter,'.001.001.data'),'w',ieee); fwrite(fid,state.V(:,:,:,i),prec); fclose(fid);
fid=fopen(strcat('UVEL.',n_iter,'.001.001.data'),'w',ieee); fwrite(fid,state.U(:,:,:,i),prec); fclose(fid);
fid=fopen(strcat('WVEL.',n_iter,'.001.001.data'),'w',ieee); fwrite(fid,state.W(:,:,:,i),prec); fclose(fid);

end