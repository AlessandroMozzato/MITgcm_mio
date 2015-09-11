function [my3dFld]=profiles_subgrid_stats_format(VV,choiceFld,COORD);
%VV variable choice
%choiceFld stat choice
%COORD is the coordinate type

doSave=1;

%========= PART 1 : load grid & atlases ========

gcmfaces_global;

listSGN=[0 45 30 18 15 10 9 6 5 3 2 1];

%========= PART 2 : load and average estimates of std ========

dirData='./';
if strcmp(COORD,'depth');
  nlev=length(mygrid.RC);
else;
  eval(['load ' myenv.gcmfaces_dir 'gcmfaces_devel/RCsig0.mat RCsig0;']);
  nlev=length(RCsig0);
end;

dirRaw=[dirData 'stats/'];
dirAssembled=[dirData 'stats/'];

listStats={'prc10','mea','med','prc90','std','iqr','mad'};
suff=listStats{choiceFld};

my3dFld=mygrid.mskC;
for lev=1:nlev-1;
test0=dir([dirAssembled VV '_k' num2str(lev) '_' suff '.mat']);
if ~isempty(test0);
  eval(['load ' dirAssembled VV '_k' num2str(lev) '_' suff '.mat;']);
else;
  myFld=NaN*mygrid.RAC;
end;
my3dFld(:,:,lev)=myFld;
end;
my3dFld(:,:,nlev)=my3dFld{1}(1,1,nlev-1);

if doSave;
  tmp1=convert2gcmfaces(my3dFld);
  write2file([dirData VV '_' suff '.bin'],tmp1);
end;

