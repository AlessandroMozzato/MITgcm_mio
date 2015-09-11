% read obcs

cd /scratch/general/am8e13/cs_36km_tutorial/input_obcs/

accuracy = 'real*4';

%file_name_complete = strcat(file_name,'_',num2str(year));

file_name_complete = 'OBEt_arctic_210x192.bin' ; 

fprintf('now reading %s \n',file_name_complete)

fid = fopen( file_name_complete, 'r', 'b' );  

% Read in the data.                                                                                                               
data = fread( fid, accuracy ); 

fclose(fid);

if length(data)==1344000
datares = reshape(data,210,50,128);
elseif length(data)==1228800
datares = reshape(data,192,50,128); 
else
    fprintf('dimension of file incorrect')
end
%figure(2)
%plot(datares)

% calculate flux

%% ------------------------------------------------------------------------
% Specify the number of grid boxes. Could look it up in the nc file, but
% I'm lazy.

nx = 210;
ny = 192;
nz = 50;

%% ------------------------------------------------------------------------

% Open the nc file.
ncid = netcdf.open( '/scratch/general/am8e13/results36km/grid.nc', 'NOWRITE' );

% Load the required fields.
hfacw = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacW' ), [ 0 0 0 ], [ nx+1 ny nz ] );
dyg = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'dyG' ), [ 0 0 ], [ nx+1 ny ] );
drf = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'drF' ), 0, nz );

% Close the nc file.
netcdf.close( ncid );

%% ------------------------------------------------------------------------

% % Open the nc file.
 ncid = netcdf.open( '/scratch/general/am8e13/results_spinup1/state.nc', 'NOWRITE' );
% 
% % Load the required fields.
 u = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'U' ), [ 0 0 0 6 ], [ nx+1 ny nz 170 ] );
 v = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'V' ), [ 0 0 0 6 ], [ nx ny+1 nz 1 ] );
 s = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 6 ], [ nx ny nz 100 ] );
 t = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 6 ], [ nx ny nz 1 ] );

%size(u)

% Close the nc file.
netcdf.close( ncid );

%% ------------------------------------------------------------------------

% Calculate the area of the western cell face.
dydz = hfacw .* repmat( dyg, [ 1 1 nz ] ) .* ...
    permute( repmat( drf, [ 1 ny nx+1 ] ), [ 3 2 1 ] );

%% ------------------------------------------------------------------------

%psi_tot = zeros(nx+1,ny+1,size(u,4)) ;

% Average of timesteps for velocity
%for i = 1 : size(u,4)

%utemp = u(:,:,:,i);

%dydz_ob = dydz(1:210,:,:) ;

%% ------------------------------------------------------------------------

% Calculate the volume flux through the western face.
for i = 1:size(u,4)
    tempflux = u(:,:,:,i) .* squeeze(dydz(:,:,:));
    fluxE(i) = sum(sum(tempflux(210,:,:)));
    fluxW(i) = sum((sum(tempflux(2,:,:))));
    fluxN(i) = sum((sum(tempflux(:,2,:))));
    fluxS(i) = sum((sum(tempflux(:,191,:))));
end

figure(1)

plot(fluxE,'y');
hold on
plot(fluxW,'r');
plot(fluxN,'g');
plot(fluxS,'b');
%% ------------------------------------------------------------------------

% % Open the nc file.
 ncid = netcdf.open( '/scratch/general/am8e13/results_ext/state.nc', 'NOWRITE' );
% 
% % Load the required fields.
 u = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'U' ), [ 0 0 0 6 ], [ nx+1 ny nz 170 ] );
 v = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'V' ), [ 0 0 0 6 ], [ nx ny+1 nz 1 ] );
 s = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 6 ], [ nx ny nz 100 ] );
 t = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 6 ], [ nx ny nz 1 ] );

%size(u)

% Close the nc file.
netcdf.close( ncid );

%% ------------------------------------------------------------------------

% Calculate the area of the western cell face.
dydz = hfacw .* repmat( dyg, [ 1 1 nz ] ) .* ...
    permute( repmat( drf, [ 1 ny nx+1 ] ), [ 3 2 1 ] );

%% ------------------------------------------------------------------------

%psi_tot = zeros(nx+1,ny+1,size(u,4)) ;

% Average of timesteps for velocity
%for i = 1 : size(u,4)

%utemp = u(:,:,:,i);

%dydz_ob = dydz(1:210,:,:) ;

%% ------------------------------------------------------------------------

% Calculate the volume flux through the western face.
for i = 1:size(u,4)
    tempflux = u(:,:,:,i) .* squeeze(dydz(:,:,:));
    fluxE(i) = sum(sum(tempflux(210,:,:)));
    fluxW(i) = sum((sum(tempflux(2,:,:))));
    fluxN(i) = sum((sum(tempflux(:,2,:))));
    fluxS(i) = sum((sum(tempflux(:,191,:))));
end

figure(1)

plot(fluxE,'y:');
hold on
plot(fluxW,'r:');
plot(fluxN,'g:');
plot(fluxS,'b:');

% Integrate in the vertical.
%uflux = sum( uflux, 3 );

cd ~/MITgcm_mio