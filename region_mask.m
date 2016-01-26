% This script creates region mask files
% 3 regions were selected: Arctic, North Atlantic, Norwegian basin

nx = 210 ; ny = 192 ; nz = 50 ;
ncid = netcdf.open( '/scratch/general/am8e13/results36km/grid.nc', 'NOWRITE' );
hfacc = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacC' ), [ 0 0 0 ], [ nx ny nz ] , [ 1 1 1 ] );
netcdf.close( ncid );

ieee='b';
prec='real*4';

% Arctic
mask1 = zeros(nx,ny,nz) ;
mask1(54:76,11:41,:) = 1 ;
mask1(69:76,41:59,:) = 1 ;
mask1(76:179,:,:) = 1 ;
%mask1(hfacc==0) = 0 ;
% Norwegian Basin
%mask2 = zeros(nx,ny,nz) ;
mask1(38:69,41:101,:) = 2 ;
mask1(26:41,51:91,:) = 2 ;
mask1(69:76,59:85,:) = 2 ;
%mask1(hfacc==0) = 0 ;
% North Atlantic
%mask3 = zeros(nx,ny,nz) ;
mask1(1:76,100:192,:) = 3 ;
mask1(1:26,51:91,:) = 3 ;
mask1(1:31,91:101,:) =3 ;
mask1(hfacc==0) = 0 ;


fid=fopen('/scratch/general/am8e13/perturbation_fields/mask_regions','w',ieee); 
fwrite(fid,mask1,prec); 
fclose(fid);

% fid=fopen('/scratch/general/am8e13/perturbation_fields/mask2','w',ieee); 
% fwrite(fid,mask2,prec); 
% fclose(fid);
% 
% fid=fopen('/scratch/general/am8e13/perturbation_fields/mask3','w',ieee); 
% fwrite(fid,mask3,prec); 
% fclose(fid);