%% ------------------------------------------------------------------------
% Flush memory, etc.

clear;
%close all;
clc;

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

% Open the nc file.
ncid = netcdf.open( '/scratch/general/am8e13/results_spinup1/state.nc', 'NOWRITE' );

% Load the required fields.
u = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'U' ), [ 0 0 0 6 ], [ nx+1 ny nz 85 ] );
v = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'V' ), [ 0 0 0 6 ], [ nx ny+1 nz 1 ] );
s = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 6 ], [ nx ny nz 1 ] );
t = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 6 ], [ nx ny nz 1 ] );

size(u)

% Close the nc file.
netcdf.close( ncid );

%% ------------------------------------------------------------------------

% Calculate the area of the western cell face.
dydz = hfacw .* repmat( dyg, [ 1 1 nz ] ) .* ...
    permute( repmat( drf, [ 1 ny nx+1 ] ), [ 3 2 1 ] );

%% ------------------------------------------------------------------------

% Average of timesteps for velocity

u = mean(u,4);

%% ------------------------------------------------------------------------

% Calculate the volume flux through the western face.
uflux = u .* dydz;

%% ------------------------------------------------------------------------

% Integrate in the vertical.
uflux = sum( uflux, 3 );

%% ------------------------------------------------------------------------

% Preallocate the streamfunction to the correct size.
psi = zeros( nx+1, ny+1 );

% Do the integration, placing the streamfunction on vorticity points.
psi( :, 2:ny+1 ) = cumsum( -uflux, 2 );

%% ------------------------------------------------------------------------

% Make a land mask with NaNs at ocean points.
land = hfacw(:,:,1);
land( land == 0 ) = -999999.;
land( land > 0 ) = NaN;

% Make an ocean mask with NaNs at land points.
ocean = hfacw(:,:,1);
ocean( ocean == 0 ) = NaN;
ocean( ocean > 0 ) = 1.;

% Draw a nice figure.

figure(2);

h1 = imagesc( land' );

set( gca, 'ydir', 'normal' );
set( h1, 'alphadata', ~isnan( land' ) );

hold on;

h2 = imagesc( ( psi(1:nx+1,1:ny)' .* ocean' )/1.E6 );

set( h2, 'alphadata', ~isnan( ocean' ) );

[ c3 h3 ] = contour( psi(:,:,:)'/1.E6, ( -332.5:35.:332.5 ), '-k' );

set( h3, 'linewidth', 1 )

axis equal tight;

caxis( [ -350 350 ] );
cmap = colormap( b2r( -100,100 ) );
cmap = [ 0 0 0; cmap ];
colormap( cmap );

colorbar;

set( gcf, 'color', 'w' );


%% ------------------------------------------------------------------------
