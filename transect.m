% Transect

S = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','S') ; 
T = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','Temp') ;

bathy = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ;

mw = 0.18 + 9.2*10^(-8)*x + 0.9*log(x);