% This script creates region mask files
% 3 regions were selected: Arctic, North Atlantic, Norwegian basin

res = 36 ;

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

% Arctic
mask1 = zeros(nx,ny,nz) ;
mask1(54*k:76*k,11*k:41*k,:) = 1 ;
mask1(69*k:76*k,41*k:59*k,:) = 1 ;
mask1(76*k:179*k,:,:) = 1 ;
% Norwegian Basin
mask1(38*k:69*k,41*k:101*k,:) = 2 ;
mask1(26*k:41*k,51*k:91*k,:) = 2 ;
mask1(69*k:76*k,59*k:85*k,:) = 2 ;
% North Atlantic
mask1(1:76*k,100*k:192*k,:) = 3 ;
mask1(1:26*k,51*k:91*k,:) = 3 ;
mask1(1:31*k,91*k:101*k,:) =3 ;
mask1(hfacc==0) = 0 ;

writebin(strcat('/scratch/general/am8e13/perturbation_fields/mask_regions_',int2str(res),'km'),mask1)
% fid=fopen(strcat('/scratch/general/am8e13/perturbation_fields/mask_regions_',int2str(res),'km'),'w',ieee); 
% fwrite(fid,mask1,prec); 
% fclose(fid);

% fid=fopen('/scratch/general/am8e13/perturbation_fields/mask2','w',ieee); 
% fwrite(fid,mask2,prec); 
% fclose(fid);
% 
% fid=fopen('/scratch/general/am8e13/perturbation_fields/mask3','w',ieee); 
% fwrite(fid,mask3,prec); 
% fclose(fid);