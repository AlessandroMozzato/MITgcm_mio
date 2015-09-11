%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate lateral boundary conditions

clear all, close all
cd /skylla/arctic/run_template
GRID_25; dpt=dpt25; thk=thk25; clear *25
nx=420; ny=384; nz=50; nt=230;
DXG=readbin('DXG.bin',[nx ny]); DYG=readbin('DYG.bin',[nx ny]);
HFACS=readbin('/skylla/arctic/output/cube81/hFacS.data',[nx ny nz]);
HFACW=readbin('/skylla/arctic/output/cube81/hFacW.data',[nx ny nz]);
OBWmask=squeeze(HFACW(2,:,:)); OBWmask(ny,:)=0;
OBEmask=squeeze(HFACW(nx,:,:));
OBNmask=squeeze(HFACS(:,ny,:)); OBNmask(1,:)=0;
for k=1:nz
  OBWmask(:,k)=thk(k)*OBWmask(:,k).*DYG(2,:)';
  OBEmask(:,k)=thk(k)*OBEmask(:,k).*DYG(nx,:)';
  OBNmask(:,k)=thk(k)*OBNmask(:,k).*DXG(:,ny);
end

cd /skylla/arctic/run_template2
DXG=readbin('DXG.bin',[nx/2 ny/2]); DYG=readbin('DYG.bin',[nx/2 ny/2]);
HFACS=readbin('/skylla/arctic/output/arctic2/base/hFacS.data',[nx/2 ny/2 nz]);
HFACW=readbin('/skylla/arctic/output/arctic2/base/hFacW.data',[nx/2 ny/2 nz]);
OBWmask2=squeeze(HFACW(2,:,:)); OBWmask2(ny/2,:)=0;
OBEmask2=squeeze(HFACW(nx/2,:,:));
OBNmask2=squeeze(HFACS(:,ny/2,:)); OBNmask2(1,:)=0;
for k=1:nz
  OBWmask2(:,k)=thk(k)*OBWmask2(:,k).*DYG(2,:)';
  OBEmask2(:,k)=thk(k)*OBEmask2(:,k).*DYG(nx/2,:)';
  OBNmask2(:,k)=thk(k)*OBNmask2(:,k).*DXG(:,ny/2);
end

cd /skylla/arctic
pin='run_template_cube81/+OB1992_2010/';
pout='run_template_cube81/+OB1992_2010_c81_36km/';

tmpin=readbin([pin 'OBNt_arctic_420x384.stable'],[nx nz nt]);
tmpout=(tmpin(1:2:nx,:,:)+tmpin(2:2:nx,:,:))/2;
writebin([pout 'OBNt_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBNs_arctic_420x384.stable'],[nx nz nt]);
tmpout=(tmpin(1:2:nx,:,:)+tmpin(2:2:nx,:,:))/2;
writebin([pout 'OBNs_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBNu_arctic_420x384.bin'],[nx nz nt]);
tmpout=(tmpin(1:2:nx,:,:)+tmpin(2:2:nx,:,:))/2;
writebin([pout 'OBNu_arctic_210x192.bin'],tmpout)

% balance so that output is same as input
tmpin=readbin([pin 'OBNv_arctic_420x384.balance'],[nx nz nt]);
tmpout=(tmpin(1:2:nx,:,:)+tmpin(2:2:nx,:,:))/2;
for t=1:nt
  OBN=sum(sum(tmpin(:,:,t).*OBNmask));
  OBN2=sum(sum(tmpout(:,:,t).*OBNmask2));
  tmpout(:,:,t)=tmpout(:,:,t)+(OBN-OBN2)/sum(OBNmask2(:));
end
writebin([pout 'OBNv_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBWt_arctic_420x384.stable'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
writebin([pout 'OBWt_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBWs_arctic_420x384.stable'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
writebin([pout 'OBWs_arctic_210x192.bin'],tmpout)

% balance so that output is same as input
tmpin=readbin([pin 'OBWu_arctic_420x384.bin'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
for t=1:nt
  OBW=sum(sum(tmpin(:,:,t).*OBWmask));
  OBW2=sum(sum(tmpout(:,:,t).*OBWmask2));
  tmpout(:,:,t)=tmpout(:,:,t)+(OBW-OBW2)/sum(OBWmask2(:));
end
writebin([pout 'OBWu_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBWv_arctic_420x384.bin'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
writebin([pout 'OBWv_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBEt_arctic_420x384.stable'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
writebin([pout 'OBEt_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBEs_arctic_420x384.stable'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
writebin([pout 'OBEs_arctic_210x192.bin'],tmpout)

% balance so that output is same as input
tmpin=readbin([pin 'OBEu_arctic_420x384.bin'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
for t=1:nt
  OBE=sum(sum(tmpin(:,:,t).*OBEmask));
  OBE2=sum(sum(tmpout(:,:,t).*OBEmask2));
  tmpout(:,:,t)=tmpout(:,:,t)+(OBE-OBE2)/sum(OBEmask2(:));
end
writebin([pout 'OBEu_arctic_210x192.bin'],tmpout)

tmpin=readbin([pin 'OBEv_arctic_420x384.bin'],[ny nz nt]);
tmpout=(tmpin(1:2:ny,:,:)+tmpin(2:2:ny,:,:))/2;
writebin([pout 'OBEv_arctic_210x192.bin'],tmpout)
eval(['cd /skylla/arctic/' pout]); nx=210; ny=192;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stabilize T/S

tmp=readbin('/skylla/arctic/output/arctic2/base/hFacC.data',[nx ny nz]);
maskW=squeeze(tmp(1,:,:));  maskW(find(maskW))=1;  maskW(find(~maskW))=nan;
maskE=squeeze(tmp(nx,:,:)); maskE(find(maskE))=1;  maskE(find(~maskE))=nan;
maskN=squeeze(tmp(:,ny,:)); maskN(find(maskN))=1;  maskN(find(~maskN))=nan;

for t=1:nt, mydisp(t)
  T=readbin('OBEt_arctic_210x192.bin',[ny nz],1,'real*4',t-1).*maskE;
  S=readbin('OBEs_arctic_210x192.bin',[ny nz],1,'real*4',t-1).*maskE;
  R=rho(S,T,0);
  for j=1:ny
    ix=find(diff(R(j,:))<0);
    while ~isempty(ix)
      T(j,min(ix)+1)=T(j,min(ix));
      S(j,min(ix)+1)=S(j,min(ix));
      r=rho(S(j,:),T(j,:),0); ix=find(diff(r)<0);
  end, end
  for k=1:nz
    if any(~isnan(T(:,k)))
      T(:,k)=xpolate(T(:,k)); S(:,k)=xpolate(S(:,k));
    else
      T(:,k)=T(:,k-1); S(:,k)=S(:,k-1);
  end, end
  writebin('OBEs_arctic_210x192.stable',S,1,'real*4',t-1);
  writebin('OBEt_arctic_210x192.stable',T,1,'real*4',t-1);

  T=readbin('OBWt_arctic_210x192.bin',[ny nz],1,'real*4',t-1).*maskW;
  S=readbin('OBWs_arctic_210x192.bin',[ny nz],1,'real*4',t-1).*maskW;
  R=rho(S,T,0);
  for j=1:ny
    ix=find(diff(R(j,:))<0);
    while ~isempty(ix)
      T(j,min(ix)+1)=T(j,min(ix));
      S(j,min(ix)+1)=S(j,min(ix));
      r=rho(S(j,:),T(j,:),0); ix=find(diff(r)<0);
  end, end
  for k=1:nz
    if any(~isnan(T(:,k)))
      T(:,k)=xpolate(T(:,k)); S(:,k)=xpolate(S(:,k));
    else
      T(:,k)=T(:,k-1); S(:,k)=S(:,k-1);
  end, end
  writebin('OBWs_arctic_210x192.stable',S,1,'real*4',t-1);
  writebin('OBWt_arctic_210x192.stable',T,1,'real*4',t-1);

  T=readbin('OBNt_arctic_210x192.bin',[nx nz],1,'real*4',t-1).*maskN;
  S=readbin('OBNs_arctic_210x192.bin',[nx nz],1,'real*4',t-1).*maskN;
  R=rho(S,T,0);
  for j=1:nx
    ix=find(diff(R(j,:))<0);
    while ~isempty(ix)
      T(j,min(ix)+1)=T(j,min(ix));
      S(j,min(ix)+1)=S(j,min(ix));
      r=rho(S(j,:),T(j,:),0); ix=find(diff(r)<0);
  end, end
  for k=1:nz
    if any(~isnan(T(:,k)))
      T(:,k)=xpolate(T(:,k)); S(:,k)=xpolate(S(:,k));
    else
      T(:,k)=T(:,k-1); S(:,k)=S(:,k-1);
  end, end
  writebin('OBNs_arctic_210x192.stable',S,1,'real*4',t-1);
  writebin('OBNt_arctic_210x192.stable',T,1,'real*4',t-1); 
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make sure that no freezing will happen at edges

OBt=readbin('OBEt_arctic_210x192.stable',[ny nz nt]);
OBs=readbin('OBEs_arctic_210x192.stable',[ny nz nt]);
ft=swfreezetemp(OBs(:,1,:),0);
clf, subplot(311), mypcolor(squeeze(OBt(:,1,:))); thincolorbar
subplot(312), mypcolor(squeeze(ft)); thincolorbar
subplot(313), mypcolor(squeeze(OBt(:,1,:)-ft)); thincolorbar

OBt=readbin('OBWt_arctic_210x192.stable',[ny nz nt]);
OBs=readbin('OBWs_arctic_210x192.stable',[ny nz nt]);
ft=swfreezetemp(OBs(:,1,:),0);
obt=OBt(:,1,:);
obt(find(obt<ft+.05))=ft(find(obt<ft+.05))+.05;
OBt(:,1,:)=obt;
writebin('OBWt_arctic_210x192.stable',OBt);
clf, subplot(311), mypcolor(squeeze(OBt(:,1,:))); thincolorbar
subplot(312), mypcolor(squeeze(ft)); thincolorbar
subplot(313), mypcolor(squeeze(OBt(:,1,:)-ft)); thincolorbar

OBt=readbin('OBNt_arctic_210x192.stable',[nx nz nt]);
OBs=readbin('OBNs_arctic_210x192.stable',[nx nz nt]);
ft=swfreezetemp(OBs(:,1,:),0);
clf, subplot(311), mypcolor(squeeze(OBt(:,1,:))); thincolorbar
subplot(312), mypcolor(squeeze(ft)); thincolorbar
subplot(313), mypcolor(squeeze(OBt(:,1,:)-ft)); thincolorbar


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check that BCs are balanced

OBW=1:nt; OBE=1:nt; OBN=1:nt;
for t=1:nt, mydisp(t)
  tmp=readbin('OBWu_arctic_210x192.bin',[ny nz],1,'real*4',t-1);
  OBW(t)=sum(sum(tmp.*OBWmask2));
  tmp=readbin('OBEu_arctic_210x192.bin',[ny nz],1,'real*4',t-1);
  OBE(t)=sum(sum(tmp.*OBEmask2));
  tmp=readbin('OBNv_arctic_210x192.bin',[nx nz],1,'real*4',t-1);
  OBN(t)=sum(sum(tmp.*OBNmask2));
end
t=1:nt; clf, plot(t,OBN-OBW,t,OBE,t,OBN-OBW+OBE)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check that BCs are stable

clf reset
tmp=readbin('/skylla/arctic/output/arctic2/base/hFacC.data',[nx ny nz]);

maskW=squeeze(tmp(1,:,:));  maskW(find(maskW))=1;  maskW(find(~maskW))=nan;
maskE=squeeze(tmp(nx,:,:)); maskE(find(maskE))=1;  maskE(find(~maskE))=nan;
maskN=squeeze(tmp(:,ny,:)); maskN(find(maskN))=1;  maskN(find(~maskN))=nan;

OBs=readbin('OBEs_arctic_210x192.stable',[ny nz nt]);
OBt=readbin('OBEt_arctic_210x192.stable',[ny nz nt]);
OBr=rho(OBs,OBt,0*OBs);
for t=1:nt
    clf
    tmp=OBs(:,nz:-1:1,t).*maskE(:,nz:-1:1);
    subplot(311), mypcolor(tmp'); thincolorbar
    title(datestr(datenum(1992,t,15)))
    tmp=OBt(:,nz:-1:1,t).*maskE(:,nz:-1:1);
    subplot(312), mypcolor(tmp'); thincolorbar
    tmp1=OBr(:,(nz-1):-1:1,t).*maskE(:,(nz-1):-1:1);
    tmp2=OBr(:,nz:-1:2,t)    .*maskE(:,nz:-1:2);
    subplot(313), mypcolor(tmp1'-tmp2');
    disp([t max(tmp1(:)-tmp2(:))])
    thincolorbar, pause(.01)
end

OBs=readbin('OBWs_arctic_210x192.stable',[ny nz nt]);
OBt=readbin('OBWt_arctic_210x192.stable',[ny nz nt]);
OBr=rho(OBs,OBt,0*OBs);
for t=1:nt
    clf
    tmp=OBs(:,nz:-1:1,t).*maskW(:,nz:-1:1);
    subplot(311), mypcolor(tmp'); thincolorbar
    title(datestr(datenum(1992,t,15)))
    tmp=OBt(:,nz:-1:1,t).*maskW(:,nz:-1:1);
    subplot(312), mypcolor(tmp'); thincolorbar
    tmp1=OBr(:,(nz-1):-1:1,t).*maskW(:,(nz-1):-1:1);
    tmp2=OBr(:,nz:-1:2,t)    .*maskW(:,nz:-1:2);
    subplot(313), mypcolor(tmp1'-tmp2');
    disp([t max(tmp1(:)-tmp2(:))])
    thincolorbar, pause(.01)
end

OBs=readbin('OBNs_arctic_210x192.stable',[nx nz nt]);
OBt=readbin('OBNt_arctic_210x192.stable',[nx nz nt]);
OBr=rho(OBs,OBt,0*OBs);
for t=1:nt
    clf
    tmp=OBs(:,nz:-1:1,t).*maskN(:,nz:-1:1);
    subplot(311), mypcolor(tmp'); thincolorbar
    title(datestr(datenum(1992,t,15)))
    tmp=OBt(:,nz:-1:1,t).*maskN(:,nz:-1:1);
    subplot(312), mypcolor(tmp'); thincolorbar
    tmp1=OBr(:,(nz-1):-1:1,t).*maskN(:,(nz-1):-1:1);
    tmp2=OBr(:,nz:-1:2,t)    .*maskN(:,nz:-1:2);
    subplot(313), mypcolor(tmp1'-tmp2');
    disp([t max(tmp1(:)-tmp2(:))])
    thincolorbar, pause(.01)
end