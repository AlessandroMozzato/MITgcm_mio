% This script read and write PickupFilesv

% pickup.0000829440.meta  pickup_ptracers.0000829440.meta  pickup_seaice.0000829440.meta
% =>pwd
% /scratch/general/am8e13/filestheia

%cd /scratch/general/am8e13/filestheia

%accuracy = 'real*4';

%fid = fopen('pickup.0000829440.data', 'r', 'b');   

% Read in the data.                                                                                                               
%data = fread( fid, accuracy ); 
%fclose(fid);

ff = rdmnc('pickup.nc') ;

%cd ~/MITgcm_mio/