function [Psi,x,y] = barotropic_psi(GRID,u)
%barotropic_psi(grid,u)
%
%Calculates depth integrated volume transport (m^3/s).
%
%e.g.
%>> G=loadgrid('expt1');
%>> S=loadstate('expt1');
%>> [psi,x,y]=barotropic_psi(G,S.U);
%>> [c,h]=contourf(x,y, sq(psi)'/1e6 );clabel(c,h)
%
%Written by adcroft@mit.edu, 2001
%$Header:

hfacs = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacS') ; 
rac = ncread('/scratch/general/am8e13/results36km/grid.nc','rA') ;%,'rA','rAz','rAw','rAs');
drf = ncread('/scratch/general/am8e13/results36km/grid.nc','drF') ;
hfacw = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ;
dyg = ncread('/scratch/general/am8e13/results36km/grid.nc','dyG') ;
GRID = struct('hfacs',hfacs,'rac',rac,'drf',drf,'hfacw',hfacw,'dyg','dyg');

%U = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','U') ;
U = load('U.mat');

N=size(GRID.hfacs);
nx=size(GRID.rac,1);
ny=size(GRID.rac,2);
nr=prod(size(GRID.drf));

DRF=spdiags(GRID.drf,0,nr,nr);
dz=reshape(GRID.hfacw,[nx*ny nr])*DRF;
area=dz.*( GRID.dyg(:)*ones(1,nr) );
area=reshape(area, N);

U=sum(u.*area,3);
U(end+1,:)=U(1,:);
Psi=U;

Psi=zeros(nx+1,ny+1);

for k=1:ny;
 Psi(:,k+1)=Psi(:,k)-U(:,k);
end

msku=max(GRID.hfacw(:,:,1),GRID.hfacw(:,:,end)); msku(find(msku~=0))=1;
mskv=max(GRID.hfacs(:,:,1),GRID.hfacs(:,:,end)); mskv(find(mskv~=0))=1;
mskz=(1-msku([1:end 1],[1 1:end])).*(1-msku([end 1:end],[1 1:end]));
mskz=mskz.*(1-mskv([1:end 1],[1:end end])).*(1-mskv([end 1:end],[1:end end]));
%mskc=1-GRID.mskc([1:end 1],[1:end end],1);
%mskz=mskc.*mskc([end 1:end-1],:).*mskc(:,[end 1:end-1]).*mskc([end 1:end-1],[end 1:end-1]);
PsiC=mean(Psi(:,end));
Psi=(Psi-PsiC).*(1-mskz);

x=GRID.xg(:,1); x(end+1)=2*x(end)-x(end-1);
y=GRID.yg(1,:); y(end+1)=2*y(end)-y(end-1);