function psi = calc_psi( u, grid )
% global barotropic stream function for mitgcm model, time slabs are
% handled as cell objects, integration from north to the south (by
% convention).

%% -----------------------------------------------------------------------------
hfacw = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacW') ; 
dyg = ncread('/scratch/general/am8e13/results36km/grid.nc','dyG') ; 
Y = ncread('/scratch/general/am8e13/results36km/grid.nc','Y') ;
ny = size(Y) ;
X = ncread('/scratch/general/am8e13/results36km/grid.nc','X') ;
nx = size(X) ;
dz = ncread('/scratch/general/am8e13/results36km/grid.nc','Z') ;
nz = size(dz) ;
u = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','V') ;

grid = struct('hfacw',hfacw,'dyg',dyg, 'ny', ny, 'nx', nx, 'dz', dz, 'nz', nz);
%% -----------------------------------------------------------------------------

% Calculate the area of the western cell face.
dydz = grid.hfacw .* ...
    permute( repmat( grid.dyg, [ 1 1 grid.nz ] ), [ 3 1 2 ] ) .* ...
    repmat( grid.dz, [ 1 grid.ny grid.nx+1 ] );

%% -----------------------------------------------------------------------------

% Integrate from the north to the south (by convention), change
% integration direction by flipping the array ubar (transposed because
% of MITgcm conventions)

% Calculate flux through the western face, + change NaN to zero (removes
% masking effects)
udxdz = change( u.*dydz, '==', NaN, 0 );

% Sum in the vertical.
ubar = squeeze( sum( udxdz, 1 ) );

% Do the integration (cumulative summation), placing streamfunction on
% vorticity points.
psi = zeros( grid.ny+1, grid.nx+1 );
psi( 1:end-1, : ) = flipdim( cumsum( flipdim( ubar, 1 ), 1 ), 1 );

%% -----------------------------------------------------------------------------

  return

%% -----------------------------------------------------------------------------



