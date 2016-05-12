% This script creates tracer files
% we want to create the following tracers:
% one in the same position of the perturbation to see where it is advected
% verious in the nordic seas: one at 50, one at 600-800 one at 1-500
% two in the arctic: one at top 50m and one 1-500

res = 18;

if res == 36
    nx = 210 ; ny = 192 ; nz = 50 ;
    ncid = netcdf.open( '/scratch/general/am8e13/results36km/grid.nc', 'NOWRITE' );
    hfacc = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacC' ), [ 0 0 0 ], [ nx ny nz ] , [ 1 1 1 ] );
    netcdf.close( ncid );
    k = 1 ; 
elseif res == 18
    nx = 420 ; ny = 384 ; nz = 50 ;
    ncid = netcdf.open( '/scratch/general/am8e13/results18km/grid.nc', 'NOWRITE' );
    hfacc = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacC' ), [ 0 0 0 ], [ nx ny nz ] , [ 1 1 1 ] );
    netcdf.close( ncid );
    k = 2 ; 
elseif res == 9
    nx = 840 ; ny = 768 ; nz = 50 ;
    ncid = netcdf.open( '/scratch/general/am8e13/results9km/grid.nc', 'NOWRITE' );
    hfacc = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacC' ), [ 0 0 0 ], [ nx ny nz ] , [ 1 1 1 ] );
    netcdf.close( ncid );
    k = 4 ; 
end
ieee='b';
prec='real*4';

% Tracer on the perturbation
mask1 = zeros(nx,ny,nz) ;
mask1(34*k:42*k,67*k:83*k,36:44) = 100 ;
mask1(35*k:41*k,68*k:82*k,37:43) = 100 ;
mask1(36*k:40*k,69*k:81*k,36:42)  = 100 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/perturbation_tracer_',int2str(res),'km'),mask1)

% Nordic seas 50 meters
mask1 = zeros(nx,ny,nz) ;
mask1(28*k:62*k,56*k:85*k,1:5) = 100 ;
mask1(54*k:62*k,80*k:85*k,1:5) = 0 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/nordicseas_50m_tracer_',int2str(res),'km'),mask1)

% Nordic seas 1-500 meters
mask1 = zeros(nx,ny,nz) ;
mask1(28*k:62*k,56*k:85*k,1:24) = 100 ;
mask1(54*k:62*k,80*k:85*k,1:24) = 0 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/nordicseas_1_500m_tracer_',int2str(res),'km'),mask1)

% Nordic seas 600-800 meters
mask1 = zeros(nx,ny,nz) ;
mask1(28*k:62*k,56*k:85*k,25:27) = 100 ;
mask1(54*k:62*k,80*k:85*k,25:27) = 0 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/nordicseas_600_800m_tracer_',int2str(res),'km'),mask1)

% Arctic top 50 meters
mask1 = zeros(nx,ny,nz) ;
mask1(92*k:179*k,20:93,1:5) = 100 ;
mask1(92*k:107*k,81:93,1:5) = 0 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/arctic_50m_tracer_',int2str(res),'km'),mask1)

% Arctic top 1-500 meters
mask1 = zeros(nx,ny,nz) ;
mask1(92*k:179*k,20:93,1:24) = 100 ;
mask1(92*k:107*k,81:93,1:24) = 0 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/arctic_1_500m_tracer_',int2str(res),'km'),mask1)

% Arctic 600-800 meters
mask1 = zeros(nx,ny,nz) ;
mask1(92*k:179*k,20:93,25:27) = 100 ;
mask1(92*k:107*k,81:93,25:27) = 0 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/arctic_600_800m_tracer_',int2str(res),'km'),mask1)

% Gateways
% Fram
mask1 = zeros(nx,ny,nz) ;
mask1(77*k,56*k:86*k,:) = 100 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/fram_tracer_',int2str(res),'km'),mask1)
% Bering
mask1 = zeros(nx,ny,nz) ;
mask1(179*k,81*k:90*k,:) = 100 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/bering_tracer_',int2str(res),'km'),mask1)
% Davis
mask1 = zeros(nx,ny,nz) ;
mask1(53*k:74*k,136*k,:) = 100 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/davis_tracer_',int2str(res),'km'),mask1)
% Denmark
mask1 = zeros(nx,ny,nz) ;
mask1(38*k:49*k,101*k,:) = 100 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/denmark_tracer_',int2str(res),'km'),mask1)
% Barents
mask1 = zeros(nx,ny,nz) ;
mask1(50*k:67*k,46*k,:) = 100 ;
mask1(67*k,46*k:59*k,:) = 100 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/barents_tracer_',int2str(res),'km'),mask1)
% Norwice
mask1 = zeros(nx,ny,nz) ;
mask1(15*k,60*k:95*k,:) = 100 ;
mask1(15*k:30*k,95*k,:) = 100 ;
writebin(strcat('/scratch/general/am8e13/perturbation_fields/norwice_tracer_',int2str(res),'km'),mask1)

%mask1 = zeros(nx,ny,nz) ;
%mask1(92*k:179*k,20:93,1) = 100 ;
%mask1(92*k:107*k,81:93,1) = 0 ;
%imagesc(squeeze(mask1(:,:,1)+hfacc(:,:,1)*100))

% old arctic
% mask1(54*k:76*k,11*k:41*k,1:24) = 100 ;
% mask1(69*k:76*k,41*k:59*k,1:24) = 100 ;
%mask1(76*k:179*k,:,1:24) = 100 ;

% old nordic seas
% mask1(38*k:69*k,41*k:101*k,1:5) = 100 ;
% mask1(26*k:41*k,51*k:91*k,1:5) = 100 ;
% mask1(69*k:76*k,59*k:85*k,1:5) = 100 ;
