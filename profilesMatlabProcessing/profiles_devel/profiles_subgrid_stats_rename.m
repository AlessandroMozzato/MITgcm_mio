
dir0='./';

tmp1=dir([dir0 '*final.mat']);
for kk=1:length(tmp1);
tmp2=tmp1(kk).name;
tmp3=[tmp2(1:end-9) 'prc10.mat'];
if ~ispc;
  system(['mv ' dir0 tmp2 ' ' dir0 tmp3]);
else;
  system(['rename ' dir0 tmp2 ' ' dir0 tmp3]); %DOS equivalent
end;
end;



