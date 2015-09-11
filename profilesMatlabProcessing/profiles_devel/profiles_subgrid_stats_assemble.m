function [myFld,myFld1]=profiles_subgrid_stats_assemble(VV,KK,choiceFld,COORD);
%KK level choice
%VV variable choice
%choiceFld stat choice
%COORD is the coordinate type

doSave=1;
dirData='./';

%========= PART 1 : load grid & atlases ========

gcmfaces_global;

listSGN=[0 45 30 18 15 10 9 6 5 3 2 1]

global atlas;
test0=isempty(atlas);%no previously loaded atlas?
if ~test0; test0=~strcmp(atlas.coord,COORD); end;%same coordinate as before?
if test0;
    atlas=[];
    atlas.coord=COORD;
    %
    dirAtlases=[myenv.gcmfaces_dir 'sample_input/OCCAetcONv4GRID/'];
    if ~strcmp(atlas.coord,'depth');
      eval(['load ' myenv.gcmfaces_dir 'gcmfaces_devel/RCsig0.mat RCsig0;']);
      atlas.RC=RCsig0;
      txt=['_' atlas.coord];
    else;
      atlas.RC=-mygrid.RC;
      txt='';
    end;
    nr=length(atlas.RC);
    %
    if ~strcmp(atlas.coord,'depth');
      tmp1=read2memory([dirAtlases 'D_OWPv1_M_eccollc_90x50' txt '.bin'],[90 1170 nr 12]);
      tmp1(tmp1==0)=NaN;
      atlas.D=convert2gcmfaces(tmp1);
      %
      tmp1=1*(sum(~isnan(atlas.D),4)>2);
      tmp1(tmp1==0)=NaN;
      %
      tmp2=nanmean(atlas.D,4);                  
      tmp2=1*(tmp2<2000); 
      tmp2(tmp2==0)=NaN;
      %
      atlas.mskC=tmp1.*tmp2;
    else;
      atlas.mskC=mygrid.mskC;
    end;
    %
    if 0;%only needed for slanted diffusion
      tmp1=read2memory([dirAtlases 'T_OWPv1_M_eccollc_90x50' txt '.bin'],[90 1170 nr 12]);
      tmp1(tmp1==0)=NaN;
      atlas.T=convert2gcmfaces(tmp1);
      %
      tmp1=read2memory([dirAtlases 'S_OWPv1_M_eccollc_90x50' txt '.bin'],[90 1170 nr 12]);
      tmp1(tmp1==0)=NaN;
      atlas.S=convert2gcmfaces(tmp1);
    end;
end;

%========= PART 2 : load and average estimates of std ========

%if result was not completed, then skip:
test0=dir([dirData 'stats/' VV '_k' num2str(KK) '_' num2str(1) '.mat']);
if isempty(test0); myFld=NaN*mygrid.RAC; myFld1=myFld; return; end;

listStats={'prc10','mea','med','prc90','std','iqr','mad'};

myWeightPower=4

for sgn=listSGN;
    eval(['load ' dirData 'stats/' VV '_k' num2str(KK) '_' num2str(sgn) '.mat myStat;']);
    %"bootstrap"
    kk=find(listSGN==sgn);
    if kk==1;
        myFld=myStat;
        w=myStat.nb/(sqrt(90*1170)^myWeightPower);
        myFld.nb=w;
        for ff=1:length(listStats);
          eval(['myFld.' listStats{ff} '=myStat.' listStats{ff} '.*w;']);
        end;
    else;
        w=myStat.nb/(sgn^myWeightPower);
        myFld.nb=myFld.nb+w;
        for ff=1:length(listStats);
          eval(['myFld.' listStats{ff} '=myFld.' listStats{ff} '+myStat.' listStats{ff} '.*w;']);
        end;
    end;
end;

%THIS WAS A BUG : myFld.nb=myFld.nb+w;
for ff=1:length(listStats);
  eval(['myFld.' listStats{ff} '=(myFld.' listStats{ff} './myFld.nb);']);
end;
myFld.msk=atlas.mskC(:,:,KK);

%original value & "local" value forcing:
suff=listStats{choiceFld};
eval(['myFld1=myFld.msk.*myFld.' suff ';']);

%========= PART 3 : smoothing setup ========

if 0;%simple smoothing, which does not account for no. of obs
    eval(['myFld.mean=myFld.msk.*atlas.' VV '(:,:,KK);']);
    myFld.sm0=diffsmooth2D(myFld1,mygrid.DXC*3,mygrid.DYC*3);
    dxy=3*sqrt(mygrid.RAC);
    myFld.sm1=diffsmooth2D(myFld1,dxy,dxy);
    myFld.sm2=diffsmooth2Drotated(myFld1,dxy,dxy/10,myFld.mean);
end;


%scale the diffusive operator:
dxLarge=3*sqrt(mygrid.RAC);
dxSmall=0.1*dxLarge;

%time scale:
tmp0=dxLarge./mygrid.DXC; tmp0(isnan(myFld1))=NaN; tmp00=nanmax(tmp0);
tmp0=dxLarge./mygrid.DYC; tmp0(isnan(myFld1))=NaN; tmp00=max([tmp00 nanmax(tmp0)]);
nbt=tmp00;
nbt=ceil(1.1*2*nbt^2);

dt=1;
T=nbt*dt;

%build diffusion operator:
kLarge=dxLarge.*dxLarge/T/2;
kSmall=dxSmall.*dxSmall/T/2;

if 1;%isotropic diffusion, rather than slanted diffusion
    Kux=dxLarge.*dxLarge/T/2;
    Kvy=dxLarge.*dxLarge/T/2;
    Kuy=[]; Kvx=[];
else;%slanted diffusion
    eval(['myFld.mean=myFld.msk.*atlas.' VV '(:,:,KK);']);
    [Kux,Kuy,Kvx,Kvy]=diffrotated(kLarge,kSmall,myFld.mean);
end;

%finalize diffusion/smoothing problem set-up:
myOp.dt=1;
% myOp.nbt=nbt;
myOp.eps=1e-3;
myOp.Kux=Kux;
myOp.Kuy=Kuy;
myOp.Kvx=Kvx;
myOp.Kvy=Kvy;

%========= PART 4 : relaxation term setup ========

%1) set relaxation strength: (local <-> smoother)
%---------------------------

%use the myFld.nb index, modified as follows
w=myFld.nb;
%I do a linear transiton in log10 
w=log10(w);
%by mapping [-2 2] to [2 -1]
w=(-1-3*(w-2)/(2+2));
%go back to original units (~nb obs) and scale by nbt (nbt = 1 smoother)
w=nbt*exp( w*log(10) );
%ensure stability
w(w<1)=1;
%enforce minimum forcing
w(w>1e3*nbt)=1e3*nbt;
if 0;
    %figureL; m_map_gcmfaces(log10(myFld.nb),0,{'myCaxis',[-4 3]});
    figureL; m_map_gcmfaces(log10(w/nbt),0,{'myCaxis',[-2 2]}); return;
end;
myOp.tau=w*myOp.dt;

% myOp.tau=0.5*myOp.dt;
% myOp.tau=nbt*myOp.dt;
% myOp.tau=nbt;

%2) set relaxation field: ("local" value)
%------------------------

fldRelax=myFld1;


%========= PART 5 : resolve smoothing/relaxation problem ========
%
%   here we integrate to a balance between 
%       "local" value (relaxation term) 
%       vs  smoothing (diffusion)

myFld=gcmfaces_timestep(myOp,myFld1,fldRelax);

%plot / save result:
%===================

if 0; 
  figureL; m_map_gcmfaces(log10(myFld),0,{'myCaxis',[-1.5 0.5]});
end;

if doSave;
  eval(['save ' dirData 'stats/' VV '_k' num2str(KK) '_' suff '.mat myFld myFld1;']);
end;

