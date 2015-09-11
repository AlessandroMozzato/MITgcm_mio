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

HFacS = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacS') ; 
rac = ncread('/scratch/general/am8e13/results36km/grid.nc','rA') ;%,'rA','rAz','rAw','rAs');
drF = ncread('/scratch/general/am8e13/results36km/grid.nc','drF') ;
HFacW = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ;
dxG = ncread('/scratch/general/am8e13/results36km/grid.nc','dxG') ;
dyG = ncread('/scratch/general/am8e13/results36km/grid.nc','dyG') ;
XC = ncread('/scratch/general/am8e13/results36km/grid.nc','XC') ;
XG = ncread('/scratch/general/am8e13/results36km/grid.nc','XG') ;
YG = ncread('/scratch/general/am8e13/results36km/grid.nc','YG') ;

%GRID = struct('hfacs',hfacs,'rac',rac,'drf',drf,'hfacw',hfacw,'dyg','dyg');

%U = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','U') ;
uVeltave = load('U.mat');

nc = size(XC,2)
nr = length(drF);
nt = size(uVeltave,4);

xv = reshape(XG(1:6*nc,1:nc),[6*nc*nc,1]);
yv = reshape(YG(1:6*nc,1:nc),[6*nc*nc,1]);
xv(end+1)=xv(1);  yv(end+1)=yv(1+2*nc);
xv(end+1)=xv(1+3*nc);  yv(end+1)=yv(1)