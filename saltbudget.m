% This script performs salt budged analysis

HFacC = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ;
RAC = ncread('/scratch/general/am8e13/results36km/grid.nc','rA') ;
DRF = ncread('/scratch/general/am8e13/results36km/grid.nc','drF') ;
RF = ncread('/scratch/general/am8e13/results36km/grid.nc','RF') ;

ADVr_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','ADVr_SLT') ; 
ADVx_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','ADVx_SLT') ; 
ADVy_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','ADVy_SLT') ; 

KPPg_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','KPPg_SLT') ; 

DFrE_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','DFrE_SLT') ; 
DFrI_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','DFrI_SLT') ; 
DFxE_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','DFxE_SLT') ; 
DFyE_SLT = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','DFyE_SLT') ;

TOTSTEND = ncread('/scratch/general/am8e13/sltbudg/sltbal1.nc','TOTSTEND') ;

SFLUX = ncread('/scratch/general/am8e13/sltbudg/sltbal2.nc','SFLUX') ;

dx = size(CellVol,1) ;
dy = size(CellVol,2) ;
dz = size(CellVol,3) ;
dt = size(ADVr_SLT,4) ;

ix = linspace(1,dx,dx);
iy = linspace(1,dy,dy);
iz = linspace(1,dz,dz);

CellVol = zeros(dx,dy,dz) ;

for ix = 1: dx
    for iy = 1:dy
        for iz = 1:dz
CellVol(ix,iy,iz) = RAC(ix,iy) * DRF(iz) * HFacC(ix,iy,iz); 

        end
    end
end

Adv_tend_slt = zeros(dx,dy,dz,dt) ;
Dif_tend_slt = zeros(dx,dy,dz,dt) ;
Kpp_tend_slt = zeros(dx,dy,dz,dt) ;
Kpp_tend_slt = zeros(dx,dy,dz,dt) ;
Sflx_tend    = zeros(dx,dy,dz,dt) ;

% ADVr_SLT = squeeze(mean(ADVr_SLT,4));
% ADVx_SLT = squeeze(mean(ADVx_SLT,4));
% ADVy_SLT = squeeze(mean(ADVy_SLT,4));
% DFrE_SLT = squeeze(mean(DFrE_SLT,4));
% DFrI_SLT = squeeze(mean(DFrI_SLT,4));
% DFxE_SLT = squeeze(mean(DFxE_SLT,4));
% DFyE_SLT = squeeze(mean(DFyE_SLT,4));
% SFLUX = squeeze(SFLUX);

for ix = 1: dx
    for iy = 1:dy
        for iz = 1:dz-1
            for it = 1:dt
                
Adv_tend_slt(ix,iy,iz,it) = - ( (ADVr_SLT(ix,iy,iz,it) - ADVr_SLT(ix,iy,iz+1,it))/CellVol(ix,iy,iz) + ...
                             (ADVx_SLT(ix+1,iy,iz,it) - ADVx_SLT(ix,iy,iz,it))/CellVol(ix,iy,iz) + ...
                             (ADVy_SLT(ix,iy+1,iz,it) - ADVy_SLT(ix,iy,iz,it))/CellVol(ix,iy,iz) ) ;
 
Dif_tend_slt(ix,iy,iz,it) = - ( (DFrE_SLT(ix,iy,iz,it) - DFrE_SLT(ix,iy,iz+1,it))/CellVol(ix,iy,iz) + ...
                             (DFrI_SLT(ix,iy,iz,it) - DFrI_SLT(ix,iy,iz+1,it))/CellVol(ix,iy,iz)  + ...
                             (DFxE_SLT(ix+1,iy,iz,it) - DFxE_SLT(ix,iy,iz,it))/CellVol(ix,iy,iz)  + ...
                             (DFyE_SLT(ix,iy+1,iz,it) - DFyE_SLT(ix,iy,iz,it))/CellVol(ix,iy,iz) ) ;

Kpp_tend_slt(ix,iy,iz,it) = - ( (KPPg_SLT(ix,iy,iz,it) - KPPg_SLT(ix,iy,iz+1,it))/CellVol(ix,iy,iz)) ;

Sflx_tend (ix,iy,iz,it) = SFLUX(ix,iy,it) / (1032 * DRF(1) * HFacC(ix,iy,iz)) ;

            end
        end
    end
end

surf_salt_tend = Adv_tend_slt + Dif_tend_slt + Kpp_tend_slt + Sflx_tend ;
