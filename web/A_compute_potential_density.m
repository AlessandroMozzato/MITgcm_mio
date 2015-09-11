gmaze_pv/B_compute_relative_vorticity.m                                                             0000644 0023526 0000144 00000030662 10560413602 020023  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [OMEGA] = B_compute_relative_vorticity(SNAPSHOT)
%
% For a time snapshot, this program computes the 
% 3D relative vorticity field from 3D 
% horizontal speed fields U,V (x,y,z) as:
% OMEGA = ( -dVdz ; dUdz ; dVdx - dUdy )
%       = (   Ox  ;  Oy  ;     ZETA    )
% 3 outputs files are created.
%
% (U,V) must have same dimensions and by default are defined on
% a C-grid. 
% If (U,V) are defined on an A-grid (coming from a cube-sphere
% to lat/lon grid interpolation for example), ie at the same points
% as THETA, SALTanom, ... the global variable 'griddef' must
% be set to 'A-grid'. Then (U,V) are moved to a C-grid for the computation.
%
% ZETA is computed at the upper-right corner of the C-grid.
% OMEGAX and OMEGAY are computed at V and U locations but shifted downward
% by 1/2 grid. In case of a A-grid for (U,V), OMEGAX and OMEGAY are moved 
% to a C-grid according to the ZETA computation.
% 
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_UVEL>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_VVEL>.<netcdf_domain>.<netcdf_suff>
% OUPUT:
% ./netcdf-files/<SNAPSHOT>/OMEGAX.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/OMEGAY.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/ZETA.<netcdf_domain>.<netcdf_suff>
%
% 2006/06/07
% gmaze@mit.edu
%
% Last update: 
% 2007/02/01 (gmaze) : Fix bug in ZETA grid and add compatibility with A-grid
%
  
% On the C-grid, U and V are supposed to have the same dimensions and are
% defined like this:
%
%  y
%  ^      -------------------------
%  |      |     |     |     |     |
%  | ny   U  *  U  *  U  *  U  *  |
%  |      |     |     |     |     |
%  |   ny -- V --- V --- V --- V --
%  |      |     |     |     |     |
%  |      U  *  U  *  U  *  U  *  |
%  |      |     |     |     |     |
%  |      -- V --- V --- V --- V --
%  |      |     |     |     |     |
%  |      U  *  U  *  U  *  U  *  |
%  |      |     |     |     |     |
%  |      -- V --- V --- V --- V --
%  |      |     |     |     |     |
%  |  1   U  *  U  *  U  *  U  *  |
%  |      |     |     |     |     |
%  |    1 -- V --- V --- V --- V --
%  |       
%  |      1                 nx
%  |         1                 nx
%--|-------------------------------------> x
%  | 
%
% On the A-grid, U and V are defined on *, so we simply shift U westward by 1/2 grid
% and V southward by 1/2 grid. New (U,V) have the same dimensions as original fields
% but with first col for U, and first row for V set to NaN. Values are computed by
% averaging two contiguous values.
%

function varargout = B_compute_relative_vorticity(snapshot)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global sla netcdf_UVEL netcdf_VVEL netcdf_domain netcdf_suff griddef
pv_checkpath


%% U,V files name:
filU = strcat(netcdf_UVEL,'.',netcdf_domain);
filV = strcat(netcdf_VVEL,'.',netcdf_domain);


%% Path and extension to find them:
pathname = strcat('netcdf-files',sla,snapshot,sla);
ext      = strcat('.',netcdf_suff);


%% Load files and axis:
ferfile          = strcat(pathname,sla,filU,ext);
ncU              = netcdf(ferfile,'nowrite');
[Ulon Ulat Udpt] = coordfromnc(ncU);

ferfile          = strcat(pathname,sla,filV,ext);
ncV              = netcdf(ferfile,'nowrite');
[Vlon Vlat Vdpt] = coordfromnc(ncV);

clear ext ferfile

%% Load grid definition:
global griddef
if length(griddef) == 0
  griddef = 'C-grid'; % By default
end
switch lower(griddef)
 case {'c-grid','cgrid','c'}
    % Nothing to do here
 case {'a-grid','agrid','a'}
    disp('Found (U,V) defined on A-grid')
    % Move Ulon westward by 1/2 grid point:
     Ulon = [Ulon(1)-abs(diff(Ulon(1:2))/2) ; (Ulon(1:end-1)+Ulon(2:end))/2];
    % Move V southward by 1/2 grid point:
     Vlat = [Vlat(1)-abs(diff(Vlat(1:2))/2); (Vlat(1:end-1)+Vlat(2:end))/2];
    % Now, (U,V) axis are defined as if they came from a C-grid
    % (U,V) fields are moved to a C-grid during computation...
 otherwise
    error('The grid must be: C-grid or A-grid');
    return
end %switch griddef
  
  
%% Optionnal flags
computeZETA = 1; % Compute ZETA or not ?
global toshow % Turn to 1 to follow the computing process


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VERTICAL COMPONENT: ZETA %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% U field is on the zonal side of the c-grid and
% V field on the meridional one.
% So computing meridional gradient for U and 
% zonal gradient for V makes the relative vorticity
% zeta defined on the corner of the c-grid.

%%%%%%%%%%%%%%
%% Dimensions of ZETA field:
if toshow,disp('Dim'),end
  ny = length(Ulat)-1; 
  nx = length(Vlon)-1; 
  nz = length(Udpt); % Note that Udpt=Vdpt
  
%%%%%%%%%%%%%%
%% Pre-allocation:
if toshow,disp('Pre-allocate'),end
ZETA = zeros(nz,ny-1,nx-1).*NaN;
dx   = zeros(ny-1,nx-1);
dy   = zeros(ny-1,nx-1);

ZETA_lon = Ulon(2:nx+1);
ZETA_lat = Vlat(2:ny+1);

%%%%%%%%%%%%%%
%% Compute relative vorticity for each z-level:
if computeZETA
for iz = 1 : nz
  if toshow
    disp(strcat('Computing \zeta at depth : ',num2str(Udpt(iz)),...
	        'm (',num2str(iz),'/',num2str(nz),')'   ));
  end
  
  % Get velocities:
  U = ncU{4}(iz,:,:);
  V = ncV{4}(iz,:,:);
  switch lower(griddef)
   case {'a-grid','agrid','a'}
    % Move U westward by 1/2 grid point:
    % (1st col is set to nan, but axis defined)
    U = [ones(ny+1,1).*NaN  (U(:,1:end-1) + U(:,2:end))/2];
    % Move V southward by 1/2 grid point:
    % (1st row is set to nan but axis defined)
    V = [ones(1,nx+1).*NaN;  (V(1:end-1,:) + V(2:end,:))/2];
    % Now, U and V are defined as if they came from a C-grid
  end  
  
  % And now compute the vertical component of relative vorticity:
  % (TO DO: m_lldist accepts tables as input, so this part may be
  % done without x,y loop ...)
  for iy = 1 : ny
    for ix = 1 : nx
      if iz==1 % It's more efficient to make this test each time than
              % recomputing distance each time. m_lldist is a slow routine.
         % ZETA axis and grid distance:
         dx(iy,ix) = m_lldist([Vlon(ix+1) Vlon(ix)],[1 1]*Vlat(iy));
         dy(iy,ix) = m_lldist([1 1]*Vlon(ix),[Ulat(iy+1) Ulat(iy)]);
      end %if 
      % Horizontal gradients and ZETA:
      dVdx        = ( V(iy,ix+1)-V(iy,ix) ) / dx(iy,ix) ;
      dUdy        = ( U(iy+1,ix)-U(iy,ix) ) / dy(iy,ix) ;
      ZETA(iz,iy,ix) = dVdx - dUdy;      
    end %for ix
  end %for iy
end %for iz

%%%%%%%%%%%%%%
%% Netcdf record:

% General informations: 
netfil     = strcat('ZETA','.',netcdf_domain,'.',netcdf_suff);
units      = '1/s';
ncid       = 'ZETA';
longname   = 'Vertical Component of the Relative Vorticity';
uniquename = 'vertical_relative_vorticity';

% Open output file:
nc = netcdf(strcat(pathname,sla,netfil),'clobber');

% Define axis:
nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;

nc{'X'} = 'X';
nc{'Y'} = 'Y';
nc{'Z'} = 'Z';

nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = ZETA_lon;

nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = ZETA_lat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = Udpt;

% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = ZETA;

nc=close(nc);

clear x y z U V dx dy nx ny nz DVdx dUdy

end %if compute ZETA


%%%%%%%%%%%%%%%%%%%%%%%%%
% HORIZONTAL COMPONENTS %
%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('')
           disp('Now compute horizontal components of relative vorticity ...'); end

% U and V are defined on the same Z grid.

%%%%%%%%%%%%%%
%% Dimensions of OMEGA x and y fields:
if toshow,disp('Dim'),end
  O_nx = [length(Vlon) length(Ulon)];
  O_ny = [length(Vlat) length(Ulat)];
  O_nz = length(Udpt) - 1; % Idem Vdpt
  
%%%%%%%%%%%%%%
%% Pre-allocations:
if toshow,disp('Pre-allocate'),end
Ox = zeros(O_nz,O_ny(1),O_nx(1)).*NaN;
Oy = zeros(O_nz,O_ny(2),O_nx(2)).*NaN;

%%%%%%%%%%%%%%
%% Computation:

%% Vertical grid differences:
dZ   = diff(Udpt); 
Odpt = Udpt(1:O_nz) + dZ/2;

%% Zonal component of OMEGA:
if toshow,disp('Zonal direction ...'); end
[a dZ_3D c] = meshgrid(Vlat,dZ,Vlon); clear a c
V = ncV{4}(:,:,:);
switch lower(griddef)
   case {'a-grid','agrid','a'}
    % Move V southward by 1/2 grid point:
    % (1st row is set to nan but axis defined)
    V = cat(2,ones(O_nz+1,1,O_nx(1)).*NaN,(V(:,1:end-1,:) + V(:,2:end,:))/2);
    % Now, V is defined as if it came from a C-grid
end
Ox = - ( V(2:O_nz+1,:,:) - V(1:O_nz,:,:) ) ./ dZ_3D;
clear V dZ_3D % For memory use

%% Meridional component of OMEGA:
if toshow,disp('Meridional direction ...'); end
[a dZ_3D c] = meshgrid(Ulat,dZ,Ulon); clear a c
U = ncU{4}(:,:,:);
switch lower(griddef)
   case {'a-grid','agrid','a'}
    % Move U westward by 1/2 grid point:
    % (1st col is set to nan, but axis defined)
    U = cat(3,ones(O_nz+1,O_ny(2),1).*NaN,(U(:,:,1:end-1) + U(:,:,2:end))/2);
    % Now, V is defined as if it came from a C-grid
end  
Oy = ( U(2:O_nz+1,:,:) - U(1:O_nz,:,:) ) ./ dZ_3D;
clear U dZ_3D % For memory use

clear dZ


%%%%%%%%%%%%%%
%% Record Zonal component:
if toshow,disp('Records ...'); end

% General informations: 
netfil     = strcat('OMEGAX','.',netcdf_domain,'.',netcdf_suff);
units      = '1/s';
ncid       = 'OMEGAX';
longname   = 'Zonal Component of the Relative Vorticity';
uniquename = 'zonal_relative_vorticity';

% Open output file:
nc = netcdf(strcat(pathname,sla,netfil),'clobber');

% Define axis:
nc('X') = O_nx(1);
nc('Y') = O_ny(1);
nc('Z') = O_nz;

nc{'X'} = 'X';
nc{'Y'} = 'Y';
nc{'Z'} = 'Z';

nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = Vlon;

nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = Vlat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = Odpt;

% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = Ox;

nc=close(nc);

%%%%%%%%%%%%%%
%% Record Meridional component:
% General informations: 
netfil     = strcat('OMEGAY','.',netcdf_domain,'.',netcdf_suff);
units      = '1/s';
ncid       = 'OMEGAY';
longname   = 'Meridional Component of the Relative Vorticity';
uniquename = 'meridional_relative_vorticity';

% Open output file:
nc = netcdf(strcat(pathname,sla,netfil),'clobber');

% Define axis:
nc('X') = O_nx(2);
nc('Y') = O_ny(2);
nc('Z') = O_nz;

nc{'X'} = 'X';
nc{'Y'} = 'Y';
nc{'Z'} = 'Z';

nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = Ulon;

nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = Ulat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = Odpt;

% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = Oy;

nc=close(nc);
close(ncU);
close(ncV);

% Outputs:
OMEGA = struct(...
    'Ox',struct('value',Ox,'dpt',Odpt,'lat',Vlat,'lon',Vlon),...
    'Oy',struct('value',Oy,'dpt',Odpt,'lat',Ulat,'lon',Vlon),...
    'Oz',struct('value',ZETA,'dpt',Udpt,'lat',ZETA_lat,'lon',ZETA_lon)...
    );
switch nargout
 case 1
  varargout(1) = {OMEGA};
end
                                                                              gmaze_pv/C_compute_potential_vorticity.m                                                            0000644 0023526 0000144 00000030102 10562377040 020204  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [Q] = C_compute_potential_vorticity(SNAPSHOT,[WANTSPLPV])
% [Q1,Q2,Q3] = C_compute_potential_vorticity(SNAPSHOT,[WANTSPLPV])
%
% This file computes the potential vorticity Q from
% netcdf files of relative vorticity (OMEGAX, OMEGAY, ZETA)
% and potential density (SIGMATHETA) as
% Q = OMEGAX . dSIGMATHETA/dx + OMEGAY . dSIGMATHETA/dy + (f+ZETA).dSIGMATHETA/dz
% 
% The optional flag WANTSPLPV is set to 0 by defaut. If turn to 1,
% then the program computes the simple PV defined by:
% splQ = f.dSIGMATHETA/dz
%
% Note that none of the fields are defined on the same grid points.
% So, I decided to compute Q on the same grid as SIGMATHETA, ie. the 
% center of the c-grid.
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/OMEGAX.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/OMEGAY.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/ZETA.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/SIGMATHETA.<netcdf_domain>.<netcdf_suff>
% OUPUT:
% ./netcdf-files/<SNAPSHOT>/PV.<netcdf_domain>.<netcdf_suff>
% or 
% ./netcdf-files/<SNAPSHOT>/splPV.<netcdf_domain>.<netcdf_suff>
%
% 06/07/2006
% gmaze@mit.edu
%
  
function varargout = C_compute_potential_vorticity(snapshot,varargin)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global sla netcdf_domain netcdf_suff
pv_checkpath

%% Flags to choose which term to compute (by default, all):
FLpv1 = 1;
FLpv2 = 1;
FLpv3 = 1;
if nargin==2  % case of optional flag presents:
  if varargin{1}(1) == 1 % Case of the simple PV:
    FLpv1 = 0;
    FLpv2 = 0;
    FLpv3 = 2;
  end
end %if
%[FLpv1 FLpv2 FLpv3]


%% Optionnal flags:
global toshow % Turn to 1 to follow the computing process


%% NETCDF files:

% Path and extension to find them:
pathname = strcat('netcdf-files',sla,snapshot,sla);
%pathname = '.';
ext      = strcat('.',netcdf_suff);

% Names:
if FLpv3 ~= 2 % We don't need them for splPV
  filOx = strcat('OMEGAX'    ,'.',netcdf_domain);
  filOy = strcat('OMEGAY'    ,'.',netcdf_domain);
  filOz = strcat('ZETA'      ,'.',netcdf_domain);
end %if
  filST = strcat('SIGMATHETA','.',netcdf_domain);

% Load files and coordinates:
if FLpv3 ~= 2 % We don't need them for splPV
  ferfile             = strcat(pathname,sla,filOx,ext);
  ncOx                = netcdf(ferfile,'nowrite');
  [Oxlon Oxlat Oxdpt] = coordfromnc(ncOx);
  ferfile             = strcat(pathname,sla,filOy,ext);
  ncOy                = netcdf(ferfile,'nowrite');
  [Oylon Oylat Oydpt] = coordfromnc(ncOy);
  ferfile             = strcat(pathname,sla,filOz,ext);
  ncOz                = netcdf(ferfile,'nowrite');
  [Ozlon Ozlat Ozdpt] = coordfromnc(ncOz);
end %if
  ferfile             = strcat(pathname,sla,filST,ext);
  ncST                = netcdf(ferfile,'nowrite');
  [STlon STlat STdpt] = coordfromnc(ncST);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Then, compute the first term:  OMEGAX . dSIGMATHETA/dx  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if FLpv1
  
%%%%%  
%% 1: Compute zonal gradient of SIGMATHETA:

% Dim:
if toshow,disp('dim'),end
nx = length(STlon) - 1;
ny = length(STlat);
nz = length(STdpt);

% Pre-allocate:
if toshow,disp('pre-allocate'),end
dSIGMATHETAdx = zeros(nz,ny,nx-1)*NaN;
           dx = zeros(1,nx).*NaN;
         STup = zeros(nz,nx);
         STdw = zeros(nz,nx);

% Zonal gradient of SIGMATHETA:
if toshow,disp('grad'), end
for iy = 1 : ny
  if toshow
    disp(strcat('Computing dSIGMATHETA/dx at latitude : ',num2str(STlat(iy)),...
	        '^o (',num2str(iy),'/',num2str(ny),')'   ));
  end  
  [dx b] = meshgrid( m_lldist(STlon(1:nx+1),[1 1]*STlat(iy)), STdpt ) ; clear b
  STup   = squeeze(ncST{4}(:,iy,2:nx+1));
  STdw   = squeeze(ncST{4}(:,iy,1:nx));
  dSTdx  = ( STup - STdw ) ./ dx;
  % Change horizontal grid point definition to fit with SIGMATHETA:
  dSTdx  = ( dSTdx(:,1:nx-1) + dSTdx(:,2:nx) )./2; 
  dSIGMATHETAdx(:,iy,:) = dSTdx;
end %for iy


%%%%%
%% 2: Move OMEGAX on the same grid:
if toshow,disp('Move OMEGAX on the same grid as dSIGMATHETA/dx'), end

% Change vertical gridding of OMEGAX:
Ox = ncOx{4}(:,:,:);
Ox = ( Ox(2:nz-1,:,:) + Ox(1:nz-2,:,:) )./2;
% And horizontal gridding:
Ox = ( Ox(:,2:ny-1,:) + Ox(:,1:ny-2,:) )./2;

%%%%%
%% 3: Make both fields having same limits:
%%    (Keep points where both fields are defined)
           Ox = squeeze(Ox(:,:,2:nx));
dSIGMATHETAdx = squeeze( dSIGMATHETAdx (2:nz-1,2:ny-1,:) );

%%%%%
%% 4: Last, compute first term of PV:
PV1 = Ox.*dSIGMATHETAdx ; 

% and define axis fron the ST grid:
PV1_lon = STlon(2:length(STlon)-1);
PV1_lat = STlat(2:length(STlat)-1);
PV1_dpt = STdpt(2:length(STdpt)-1);

clear nx ny nz dx STup STdw iy dSTdx Ox dSIGMATHETAdx
end %if FLpv1




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the second term:  OMEGAY . dSIGMATHETA/dy  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if FLpv2
  
%%%%%  
%% 1: Compute meridional gradient of SIGMATHETA:

% Dim:
if toshow,disp('dim'), end
nx = length(STlon) ;
ny = length(STlat) - 1 ;
nz = length(STdpt) ;

% Pre-allocate:
if toshow,disp('pre-allocate'), end
dSIGMATHETAdy = zeros(nz,ny-1,nx).*NaN;
           dy = zeros(1,ny).*NaN;
         STup = zeros(nz,ny);
         STdw = zeros(nz,ny);

% Meridional gradient of SIGMATHETA:
% (Assuming the grid is regular, dy is independent of x)
[dy b] = meshgrid( m_lldist([1 1]*STlon(1),STlat(1:ny+1) ), STdpt ) ; clear b
for ix = 1 : nx
  if toshow
    disp(strcat('Computing dSIGMATHETA/dy at longitude : ',num2str(STlon(ix)),...
	        '^o (',num2str(ix),'/',num2str(nx),')'   ));
  end
  STup  = squeeze(ncST{4}(:,2:ny+1,ix));
  STdw  = squeeze(ncST{4}(:,1:ny,ix));
  dSTdy = ( STup - STdw ) ./ dy;
  % Change horizontal grid point definition to fit with SIGMATHETA:
  dSTdy = ( dSTdy(:,1:ny-1) + dSTdy(:,2:ny) )./2; 
  dSIGMATHETAdy(:,:,ix) = dSTdy;
end %for iy

%%%%%
%% 2: Move OMEGAY on the same grid:
if toshow,disp('Move OMEGAY on the same grid as dSIGMATHETA/dy'), end

% Change vertical gridding of OMEGAY:
Oy = ncOy{4}(:,:,:);
Oy = ( Oy(2:nz-1,:,:) + Oy(1:nz-2,:,:) )./2;
% And horizontal gridding:
Oy = ( Oy(:,:,2:nx-1) + Oy(:,:,1:nx-2) )./2;

%%%%%
%% 3: Make them having same limits:
%%    (Keep points where both fields are defined)
           Oy = squeeze(Oy(:,2:ny,:));
dSIGMATHETAdy = squeeze( dSIGMATHETAdy (2:nz-1,:,2:nx-1) );

%%%%%
%% 4: Last, compute second term of PV:
PV2 = Oy.*dSIGMATHETAdy ; 

% and defined axis fron the ST grid:
PV2_lon = STlon(2:length(STlon)-1);
PV2_lat = STlat(2:length(STlat)-1);
PV2_dpt = STdpt(2:length(STdpt)-1);


clear nx ny nz dy STup STdw dy dSTdy Oy dSIGMATHETAdy
end %if FLpv2





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the third term: ( f + ZETA ) . dSIGMATHETA/dz  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if FLpv3

%%%%%
%% 1: Compute vertical gradient of SIGMATHETA:

% Dim:
if toshow,disp('dim'), end
nx = length(STlon) ;
ny = length(STlat) ;
nz = length(STdpt) - 1 ;

% Pre-allocate:
if toshow,disp('pre-allocate'), end
dSIGMATHETAdz = zeros(nz-1,ny,nx).*NaN;
           ST = zeros(nz+1,ny,nx);
           dz = zeros(1,nz).*NaN;

% Vertical grid differences:
% STdpt contains negative values with STdpt(1) at the surface
% and STdpt(end) at the bottom of the ocean.
% So dz is positive with respect to z axis upward:
         dz = -diff(STdpt); 
[a dz_3D c] = meshgrid(STlat,dz,STlon); clear a c

% Vertical gradient:
if toshow,disp('Vertical gradient of SIGMATHETA'), end
           ST = ncST{4}(:,:,:);
	   % Z axis upward, so vertical derivative is upper-part
	   % minus lower-part:
dSIGMATHETAdz = ( ST(1:nz,:,:) - ST(2:nz+1,:,:) ) ./ dz_3D;
clear dz_3D ST

% Change vertical gridding:
dSIGMATHETAdz = ( dSIGMATHETAdz(1:nz-1,:,:) + dSIGMATHETAdz(2:nz,:,:) )./2;

if FLpv3 == 1 % Just for full PV
  
  %%%%%
  %% 2: Move ZETA on the same grid:
  if toshow,disp('Move ZETA on the same grid as dSIGMATHETA/dz'), end
  Oz = ncOz{4}(:,:,:);
  % Change horizontal gridding:
  Oz = ( Oz(:,:,2:nx-1) + Oz(:,:,1:nx-2) )./2;
  Oz = ( Oz(:,2:ny-1,:) + Oz(:,1:ny-2,:) )./2;

end %if FLpv3=1

%%%%%
%% 3: Make them having same limits:
%%    (Keep points where both fields are defined)
if FLpv3 == 1
           Oz = squeeze(Oz(2:nz,:,:));	   
end %if	   
dSIGMATHETAdz = squeeze( dSIGMATHETAdz (:,2:ny-1,2:nx-1) );


%%%%%
%% 4: Last, compute third term of PV:
% and defined axis fron the ST grid:
PV3_lon = STlon(2:length(STlon)-1);
PV3_lat = STlat(2:length(STlat)-1);
PV3_dpt = STdpt(2:length(STdpt)-1);

% Planetary vorticity:
f = 2*(2*pi/86400)*sin(PV3_lat*pi/180);
[a f c]=meshgrid(PV3_lon,f,PV3_dpt); clear a c
f = permute(f,[3 1 2]);

% Third term of PV:
if FLpv3 == 2
  % Compute simple PV, just with planetary vorticity:
  PV3 = f.*dSIGMATHETAdz ;
else
  % To compute full PV:
  PV3 = (f+Oz).*dSIGMATHETAdz ; 
end
 


clear nx ny nz dz ST Oz dSIGMATHETAdz f
end %if FLpv3



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Then, compute potential vorticity:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow,disp('Summing terms to get PV:'),end
% If we had computed the first term:
if FLpv1
  if toshow,disp('First term alone'),end
  PV = PV1;
  PV_lon=PV1_lon;PV_lat=PV1_lat;PV_dpt=PV1_dpt;
end
% If we had computed the second term:
if FLpv2
  if exist('PV') % and the first one:
    if toshow,disp('Second term added to first one'),end
    PV = PV + PV2; 
  else           % or not:
    if toshow,disp('Second term alone'),end
    PV = PV2; 
    PV_lon=PV2_lon;PV_lat=PV2_lat;PV_dpt=PV2_dpt;  
  end
end
% If we had computed the third term:
if FLpv3
  if exist('PV') % and one of the first or second one:
    if toshow,disp('Third term added to first and/or second one(s)'),end
    PV = PV + PV3; 
  else           % or not:
    if toshow,disp('Third term alone'),end
    PV = PV3;
    PV_lon=PV3_lon;PV_lat=PV3_lat;PV_dpt=PV3_dpt;  
  end
end  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow,disp('Now reccording PV file ...'),end

% General informations: 
if FLpv3 == 1
  netfil     = strcat('PV','.',netcdf_domain,'.',netcdf_suff);
  units      = 'kg/s/m^4';
  ncid       = 'PV';
  longname   = 'Potential vorticity';
  uniquename = 'potential_vorticity';
else
  netfil     = strcat('splPV','.',netcdf_domain,'.',netcdf_suff);
  units      = 'kg/s/m^4';
  ncid       = 'splPV';
  longname   = 'Simple Potential vorticity';
  uniquename = 'simple_potential_vorticity';
end %if  

% Open output file:
nc = netcdf(strcat(pathname,sla,netfil),'clobber');

% Define axis:
nc('X') = length(PV_lon);
nc('Y') = length(PV_lat);
nc('Z') = length(PV_dpt);

nc{'X'} = 'X';
nc{'Y'} = 'Y';
nc{'Z'} = 'Z';

nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = PV_lon;

nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = PV_lat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = PV_dpt;

% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = PV;

nc=close(nc);
if FLpv3 ~= 2
   close(ncOx);
   close(ncOy);
   close(ncOz);
end
close(ncST);

% Outputs:
OUT = struct('PV',PV,'dpt',PV_dpt,'lat',PV_lat,'lon',PV_lon);
switch nargout
 case 1
  varargout(1) = {OUT};
 case 2
  varargout(1) = {struct('PV1',PV1,'dpt',PV1_dpt,'lat',PV1_lat,'lon',PV1_lon)};
  varargout(2) = {struct('PV2',PV2,'dpt',PV2_dpt,'lat',PV2_lat,'lon',PV2_lon)};
 case 3
  varargout(1) = {struct('PV1',PV1,'dpt',PV1_dpt,'lat',PV1_lat,'lon',PV1_lon)};
  varargout(2) = {struct('PV2',PV2,'dpt',PV2_dpt,'lat',PV2_lat,'lon',PV2_lon)};
  varargout(3) = {struct('PV3',PV3,'dpt',PV3_dpt,'lat',PV3_lat,'lon',PV3_lon)};
end
                                                                                                                                                                                                                                                                                                                                                                                                                                                              gmaze_pv/compute_alpha.m                                                                            0000644 0023526 0000144 00000006761 10560414351 014725  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [ALPHA] = compute_alpha(SNAPSHOT)
%
% This function computes the thermal expansion coefficient from
% files of potential temperature THETA and salinity anomaly 
% SALTanom.
% SALTanom is by default a salinity anomaly vs 35PSU.
% If not, (is absolute value) set the global variable is_SALTanom to 0
%
% Files name are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_THETA>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_SALTanom>.<netcdf_domain>.<netcdf_suff>
% OUTPUT:
% ./netcdf-files/<SNAPSHOT>/ALPHA.<netcdf_domain>.<netcdf_suff>
%
% with: netcdf_* as global variables
%
% Alpha is computed with the subroutine sw_alpha from package SEAWATER
%
% 06/27/06
% gmaze@mit.edu

function varargout = compute_alpha(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_SALTanom netcdf_THETA
pv_checkpath


% Path and extension to find netcdf-files:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,netcdf_THETA,'.',netcdf_domain,'.',ext);
ncT     = netcdf(ferfile,'nowrite');
[Tlon Tlat Tdpt] = coordfromnc(ncT);

ferfile = strcat(pathname,sla,snapshot,sla,netcdf_SALTanom,'.',netcdf_domain,'.',ext);
ncS   = netcdf(ferfile,'nowrite');
[Slon Slat Sdpt] = coordfromnc(ncS); % but normaly is the same grid as T

% Salinity field ref;
global is_SALTanom
if exist('is_SALTanom')
  if is_SALTanom == 1
    bS = 35;
  else
    bS = 0;
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% surface PV flux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define axis:
nx = length(Tlon) ;
ny = length(Tlat) ;
nz = length(Tdpt) ;


% Pre-allocation:
if toshow,disp('Pre-allocate');end
ALPHA = zeros(nz,ny,nx).*NaN;

% Compute alpha:
for iz = 1 : nz
  if toshow,disp(strcat('Compute alpha for level:',num2str(iz),'/',num2str(nz)));end
  TEMP = ncT{4}(iz,:,:);
  SALT = ncS{4}(iz,:,:) + bS;
  PRES = (0.09998*9.81*Tdpt(iz))*ones(ny,nx);
  ALPHA(iz,:,:) = sw_alpha(SALT,TEMP,PRES,'ptmp');
end %for iz


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
netfil     = 'ALPHA';
units      = '1/K';
ncid       = 'ALPHA';
longname   = 'Thermal expansion coefficient';
uniquename = 'ALPHA';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(Tlon) ;
ny = length(Tlat) ;
nz = length(Tdpt) ;

nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = Tlon;
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = Tlat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = Tdpt;
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = ALPHA;

nc=close(nc);
close(ncS);
close(ncT);

% Output:
output = struct('ALPHA',ALPHA,'dpt',Tdpt,'lat',Tlat,'lon',Tlon);
switch nargout
 case 1
  varargout(1) = {output};
end
               gmaze_pv/compute_density.m                                                                          0000644 0023526 0000144 00000007674 10560445025 015325  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [RHO] = compute_density(SNAPSHOT)
%
% For a time snapshot, this program computes the 
% 3D density from potential temperature and salinity fields.
% THETA and SALTanom are supposed to be defined on the same 
% domain and grid. 
% SALTanom is by default a salinity anomaly vs 35PSU.
% If not, (is absolute value) set the global variable is_SALTanom to 0
% 
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_THETA>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_SALTanom>.<netcdf_domain>.<netcdf_suff>
% OUPUT:
% ./netcdf-files/<SNAPSHOT>/RHO.<netcdf_domain>.<netcdf_suff>
% 
% 06/21/2006
% gmaze@mit.edu
%

  
function varargout = compute_density(snapshot)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global sla netcdf_THETA netcdf_SALTanom netcdf_domain netcdf_suff
global is_SALTanom
pv_checkpath


%% THETA and SALTanom files name:
filTHETA = strcat(netcdf_THETA   ,'.',netcdf_domain);
filSALTa = strcat(netcdf_SALTanom,'.',netcdf_domain);

%% Path and extension to find them:
pathname = strcat('netcdf-files',sla,snapshot);
%pathname = '.';
ext      = strcat('.',netcdf_suff);

%% Load netcdf files:
ferfile = strcat(pathname,sla,filTHETA,ext);
ncTHETA = netcdf(ferfile,'nowrite');
THETAvariables = var(ncTHETA);

ferfile = strcat(pathname,sla,filSALTa,ext);
ncSALTa = netcdf(ferfile,'nowrite');
SALTavariables = var(ncSALTa);

%% Gridding:
% Don't care about the grid here !
% SALTanom and THETA are normaly defined on the same grid
% So we compute rho on it.

%% Flags:
global toshow % Turn to 1 to follow the computing process


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Now we compute the density
%% The routine used is densjmd95.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Axis (usual netcdf files):
if toshow,disp('Dim');end
[lon lat dpt] = coordfromnc(ncTHETA);
nx = length(lon);
ny = length(lat);
nz = length(dpt);

% Pre-allocate:
if toshow,disp('Pre-allocate');end
RHO = zeros(nz,ny,nx);

global is_SALTanom
if exist('is_SALTanom')
  if is_SALTanom == 1
    bS = 35;
  else
    bS = 0;
  end
end

% Then compute density RHO:
for iz = 1 : nz
  if toshow,disp(strcat('Compute density at level:',num2str(iz),'/',num2str(nz)));end
  
  S = SALTavariables{4}(iz,:,:) + bS; % Move the anom to an absolute field
  T = THETAvariables{4}(iz,:,:);
  P = (0.09998*9.81*dpt(iz))*ones(ny,nx);
  RHO(iz,:,:) = densjmd95(S,T,P);
  
end %for iz




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Record output:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% General informations: 
netfil     = strcat('RHO','.',netcdf_domain,'.',netcdf_suff);
units      = 'kg/m^3';
ncid       = 'RHO';
longname   = 'Density';
uniquename = 'density';

% Open output file:
nc = netcdf(strcat(pathname,sla,netfil),'clobber');

% Define axis:
nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;

nc{'X'} = 'X';
nc{'Y'} = 'Y';
nc{'Z'} = 'Z';

nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = lon;

nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = lat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = dpt;

% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = RHO;



% Close files:
close(ncTHETA);
close(ncSALTa);
close(nc);


% Output:
output = struct('RHO',RHO,'dpt',dpt,'lat',lat,'lon',lon);
switch nargout
 case 1
  varargout(1) = {output};
end
                                                                    gmaze_pv/compute_EKL.m                                                                              0000644 0023526 0000144 00000007273 10560414451 014253  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [EKL] = compute_EKL(SNAPSHOT)
%
% Here we compute the Ekmal Layer Depth as:
% EKL = 0.7 sqrt( |TAU|/RHO )/f 
%
% where:
%  TAU is the amplitude of the surface wind-stress (N/m2)
%  RHO is the density of seawater (kg/m3)
%  f is the Coriolis parameter (kg/m3)
%  EKL is the Ekman layer depth (m)
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_RHO>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_TAUX>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_TAUY>.<netcdf_domain>.<netcdf_suff>
% OUTPUT
% ./netcdf-files/<SNAPSHOT>/<netcdf_EKL>.<netcdf_domain>.<netcdf_suff>
% 
% with netcdf_* as global variables
% netcdf_EKL = 'EKL' by default
%
% 08/16/06
% gmaze@mit.edu

function varargout = compute_EKL(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_TAUX netcdf_TAUY netcdf_RHO netcdf_EKL
pv_checkpath
global EKL Tx Ty TAU RHO f


% NETCDF file name:
filTx  = netcdf_TAUX;
filTy  = netcdf_TAUY;
filRHO = netcdf_RHO;

% Path and extension to find them:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,filTx,'.',netcdf_domain,'.',ext);
ncTx    = netcdf(ferfile,'nowrite');
Tx      = ncTx{4}(1,:,:);
ferfile = strcat(pathname,sla,snapshot,sla,filTy,'.',netcdf_domain,'.',ext);
ncTy    = netcdf(ferfile,'nowrite');
Ty      = ncTy{4}(1,:,:);
[Tylon Tylat Tydpt] = coordfromnc(ncTy);

ferfile = strcat(pathname,sla,snapshot,sla,filRHO,'.',netcdf_domain,'.',ext);
ncRHO   = netcdf(ferfile,'nowrite');
RHO     = ncRHO{4}(1,:,:);
[RHOlon RHOlat RHOdpt] = coordfromnc(ncRHO);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get EKL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dim:
if toshow, disp('dim'), end
nx = length(RHOlon);
ny = length(RHOlat);
nz = length(RHOdpt);

% Pre-allocate:
if toshow, disp('pre-allocate'), end
EKL = zeros(ny,nx);

% Planetary vorticity:
f = 2*(2*pi/86400)*sin(RHOlat*pi/180);
[a f c]=meshgrid(RHOlon,f,RHOdpt); clear a c
f = permute(f,[3 1 2]);
f = squeeze(f(1,:,:));

% Windstress amplitude:
TAU = sqrt( Tx.^2 + Ty.^2 );

% Ekman Layer Depth:
EKL = 0.7* sqrt(TAU ./ RHO) ./f;
%EKL = 1.7975 * sqrt( TAU ./ RHO ./ f );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
if ~isempty('netcdf_EKL')
  netfil = netcdf_EKL;
else
  netfil = 'EKL';
end
units      = 'm';
ncid       = 'EKL';
longname   = 'Ekman Layer Depth';
uniquename = 'EKL';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(RHOlon) ;
ny = length(RHOlat) ;
nz = 1 ;

nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = RHOlon;
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = RHOlat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = RHOdpt(1);
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = EKL;

nc=close(nc);



% Output:
output = struct('EKL',EKL,'lat',RHOlat,'lon',RHOlon);
switch nargout
 case 1
  varargout(1) = {output};
end
                                                                                                                                                                                                                                                                                                                                     gmaze_pv/compute_EKLx.m                                                                             0000644 0023526 0000144 00000006731 10560414506 014442  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [EKL] = compute_EKLx(SNAPSHOT)
%
% Here we compute the Ekman Layer Depth as:
% EKL = 0.7 sqrt( TAUx/RHO )/f 
%
% where:
%  TAUx is the amplitude of the zonal surface wind-stress (N/m2)
%  RHO is the density of seawater (kg/m3)
%  f is the Coriolis parameter (kg/m3)
%  EKL is the Ekman layer depth (m)
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_RHO>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_TAUX>.<netcdf_domain>.<netcdf_suff>
% OUTPUT
% ./netcdf-files/<SNAPSHOT>/<netcdf_EKLx>.<netcdf_domain>.<netcdf_suff>
% 
% with netcdf_* as global variables
% netcdf_EKLx = 'EKLx' by default
%
% 12/04/06
% gmaze@mit.edu

function varargout = compute_EKLx(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_TAUX netcdf_RHO netcdf_EKLx
pv_checkpath
global EKL Tx Ty TAU RHO f


% NETCDF file name:
filTx  = netcdf_TAUX;
filRHO = netcdf_RHO;

% Path and extension to find them:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,filTx,'.',netcdf_domain,'.',ext);
ncTx    = netcdf(ferfile,'nowrite');
Tx      = ncTx{4}(1,:,:);

ferfile = strcat(pathname,sla,snapshot,sla,filRHO,'.',netcdf_domain,'.',ext);
ncRHO   = netcdf(ferfile,'nowrite');
RHO     = ncRHO{4}(1,:,:);
[RHOlon RHOlat RHOdpt] = coordfromnc(ncRHO);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get EKL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dim:
if toshow, disp('dim'), end
nx = length(RHOlon);
ny = length(RHOlat);
ynz = length(RHOdpt);

% Pre-allocate:
if toshow, disp('pre-allocate'), end
EKL = zeros(ny,nx);

% Planetary vorticity:
f = 2*(2*pi/86400)*sin(RHOlat*pi/180);
[a f c]=meshgrid(RHOlon,f,RHOdpt); clear a c
f = permute(f,[3 1 2]);
f = squeeze(f(1,:,:));

% Windstress amplitude:
TAU = sqrt( Tx.^2 );

% Ekman Layer Depth:
EKL = 0.7* sqrt(TAU ./ RHO) ./f;
%EKL = 1.7975 * sqrt( TAU ./ RHO ./ f );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
if ~isempty('netcdf_EKLx')
  netfil = netcdf_EKLx;
else
  netfil = 'EKLx';
end
units      = 'm';
ncid       = 'EKLx';
longname   = 'Ekman Layer Depth from TAUx';
uniquename = 'EKLx';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(RHOlon) ;
ny = length(RHOlat) ;
nz = 1 ;

nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = RHOlon;
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = RHOlat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = RHOdpt(1);
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = EKL;



% Close files:
close(ncTx);
close(ncRHO);
close(nc);



% Output:
output = struct('EKL',EKL,'lat',RHOlat,'lon',RHOlon);
switch nargout
 case 1
  varargout(1) = {output};
end
                                       gmaze_pv/compute_JBz.m                                                                              0000644 0023526 0000144 00000006542 10560415013 014316  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [JBz] = compute_JBz(SNAPSHOT)
%
% Here we compute the PV flux due to diabatic processes as
% JFz = - alpha * f * Qnet / MLD / Cw
% where:
%  alpha = 2.5*E-4 1/K is the thermal expansion coefficient
%  f = 2*OMEGA*sin(LAT) is the Coriolis parameter
%  Qnet is the net surface heat flux (W/m^2), positive downward
%  MLD is the mixed layer depth (m, positive)
%  Cw = 4187 J/kg/K is the specific heat of seawater
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_Qnet>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_MLD>.<netcdf_domain>.<netcdf_suff>
% OUTPUT:
% ./netcdf-files/<SNAPSHOT>/JBz.<netcdf_domain>.<netcdf_suff>
% 
% with: netcdf_* as global variables
%
% 06/27/06
% gmaze@mit.edu

function varargout = compute_JBz(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_Qnet netcdf_MLD
pv_checkpath


% Path and extension to find netcdf-files:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,netcdf_Qnet,'.',netcdf_domain,'.',ext);
ncQ     = netcdf(ferfile,'nowrite');
[Qlon Qlat Qdpt] = coordfromnc(ncQ);

ferfile = strcat(pathname,sla,snapshot,sla,netcdf_MLD,'.',netcdf_domain,'.',ext);
ncMLD   = netcdf(ferfile,'nowrite');
[MLDlon MLDlat MLDdpt] = coordfromnc(ncMLD);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% surface PV flux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define axis:
nx = length(Qlon) ;
ny = length(Qlat) ;
nz = length(Qdpt) ;


% Planetary vorticity:
f     = 2*(2*pi/86400)*sin(Qlat*pi/180);
[a f] = meshgrid(Qlon,f); clear a c


% Net surface heat flux:
Qnet = ncQ{4}(:,:,:);


% Mixed layer Depth:
MLD = ncMLD{4}(:,:,:);


% Coefficient:
alpha = 2.5*10^(-4); % Surface average value
Cw    = 4187;		  
coef  = - alpha / Cw;


% JBz:
JBz = zeros(nz,ny,nx).*NaN;
JBz(1,:,:) = coef*f.*Qnet./MLD;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
netfil     = 'JBz';
units      = 'kg/m3/s2';
ncid       = 'JBz';
longname   = 'Vertical PV flux due to diabatic processes';
uniquename = 'JBz';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(Qlon) ;
ny = length(Qlat) ;
nz = 1 ;

nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = Qlon;
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = Qlat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = Qdpt(1);
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = JBz;

nc=close(nc);
close(ncQ);
close(ncMLD);



% Output:
output = struct('JBz',JBz,'lat',Qlat,'lon',Qlon);
switch nargout
 case 1
  varargout(1) = {output};
end
                                                                                                                                                              gmaze_pv/compute_JFz.m                                                                              0000644 0023526 0000144 00000013634 10560414727 014335  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [JFz] = compute_JFz(SNAPSHOT)
%
% Here we compute the PV flux due to frictionnal forces as
% JFz = ( TAUx * dSIGMATHETA/dy - TAUy * dSIGMATHETA/dx ) / RHO / EKL
%
% where:
%  TAU is the surface wind-stress (N/m2)
%  SIGMATHETA is the potential density (kg/m3)
%  RHO is the density (kg/m3)
%  EKL is the Ekman layer depth (m, positive)
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_SIGMATHETA>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_TAUX>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_TAUY>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_RHO>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_EKL>.<netcdf_domain>.<netcdf_suff>
% OUTPUT:
% ./netcdf-files/<SNAPSHOT>/JFz.<netcdf_domain>.<netcdf_suff>
% 
% with netcdf_* as global variables
%
% 06/27/06
% gmaze@mit.edu

function varargout = compute_JFz(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_TAUX netcdf_TAUY netcdf_SIGMATHETA netcdf_EKL netcdf_RHO
pv_checkpath


% NETCDF file name:
filST  = netcdf_SIGMATHETA;
filTx  = netcdf_TAUX;
filTy  = netcdf_TAUY;
filRHO = netcdf_RHO;
filH   = netcdf_EKL;

% Path and extension to find them:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,filST,'.',netcdf_domain,'.',ext);
ncST     = netcdf(ferfile,'nowrite');
[STlon STlat STdpt] = coordfromnc(ncST);

ferfile = strcat(pathname,sla,snapshot,sla,filTx,'.',netcdf_domain,'.',ext);
ncTx    = netcdf(ferfile,'nowrite');
ferfile = strcat(pathname,sla,snapshot,sla,filTy,'.',netcdf_domain,'.',ext);
ncTy    = netcdf(ferfile,'nowrite');

ferfile = strcat(pathname,sla,snapshot,sla,filRHO,'.',netcdf_domain,'.',ext);
ncRHO   = netcdf(ferfile,'nowrite');
RHO     = ncRHO{4}(1,:,:);

ferfile = strcat(pathname,sla,snapshot,sla,filH,'.',netcdf_domain,'.',ext);
ncH     = netcdf(ferfile,'nowrite');
EKL     = ncH{4}(1,:,:);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First term
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dim:
if toshow, disp('dim'), end
nx = length(STlon) ;
ny = length(STlat) - 1 ;
nz = length(STdpt);

% Pre-allocate:
if toshow, disp('pre-allocate'), end
dSIGMATHETAdy = zeros(nz,ny-1,nx).*NaN;
dy       = zeros(1,ny).*NaN;
STup      = zeros(nz,ny);
STdw      = zeros(nz,ny);

% Meridional gradient of SIGMATHETA:
if toshow, disp('grad'), end
% Assuming the grid is regular, dy is independent of x:
[dy b] = meshgrid( m_lldist([1 1]*STlon(1),STlat(1:ny+1) ), STdpt ) ; clear b
for ix = 1 : nx
  if toshow, disp(strcat(num2str(ix),'/',num2str(nx))), end
  STup  = squeeze(ncST{4}(:,2:ny+1,ix));
  STdw  = squeeze(ncST{4}(:,1:ny,ix));
  dSTdy = ( STup - STdw ) ./ dy;
  % Change horizontal grid point definition to fit with SIGMATHETA:
  dSTdy = ( dSTdy(:,1:ny-1) + dSTdy(:,2:ny) )./2; 
  dSIGMATHETAdy(:,:,ix) = dSTdy;
end %for iy

% Make TAUx having same limits:
TAUx = ncTx{4}(1,2:ny,:);

% Compute first term: TAUx * dSIGMATHETA/dy
iz    = 1;
JFz_a = TAUx .* squeeze(dSIGMATHETAdy(iz,:,:)) ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Second term
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dim:
if toshow, disp('dim'), end
nx = length(STlon) - 1;
ny = length(STlat) ;
nz = length(STdpt) ;

% Pre-allocate:
if toshow, disp('pre-allocate'), end
dSIGMATHETAdx = zeros(nz,ny,nx-1).*NaN;
dx       = zeros(1,nx).*NaN;
STup      = zeros(nz,nx);
STdw      = zeros(nz,nx);

% Zonal gradient of SIGMATHETA
if toshow, disp('grad'), end
for iy = 1 : ny
  if toshow, disp(strcat(num2str(iy),'/',num2str(ny))), end
  [dx b] = meshgrid( m_lldist(STlon(1:nx+1),[1 1]*STlat(iy)), STdpt ) ; clear b
  STup    = squeeze(ncST{4}(:,iy,2:nx+1));
  STdw    = squeeze(ncST{4}(:,iy,1:nx));
  dSTdx   = ( STup - STdw ) ./ dx;
  % Change horizontal grid point definition to fit with SIGMATHETA:
  dSTdx   = ( dSTdx(:,1:nx-1) + dSTdx(:,2:nx) )./2;
  dSIGMATHETAdx(:,iy,:) = dSTdx;
end %for iy

% Make TAUy having same limits:
TAUy  = ncTy{4}(1,:,2:nx);

% Compute second term: TAUy * dSIGMATHETA/dx
iz    = 1;
JFz_b = TAUy .* squeeze(dSIGMATHETAdx(iz,:,:)) ;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finish ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Then make all terms having same limits:
nx = length(STlon) ;
ny = length(STlat) ;
nz = length(STdpt) ;
JFz_a   = squeeze(JFz_a(:,2:nx-1));
JFz_b   = squeeze(JFz_b(2:ny-1,:));
delta_e = squeeze(EKL(2:ny-1,2:nx-1));
rho     = squeeze(RHO(2:ny-1,2:nx-1));

% and finish:
JFz = (JFz_a - JFz_b)./delta_e./rho;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
netfil     = 'JFz';
units      = 'kg/m3/s2';
ncid       = 'JFz';
longname   = 'Vertical PV flux due to frictional forces';
uniquename = 'JFz';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(STlon) ;
ny = length(STlat) ;
nz = 1 ;

nc('X') = nx-2;
nc('Y') = ny-2;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = STlon(2:nx-1);
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = STlat(2:ny-1);
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = STdpt(1);
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = JFz;

nc=close(nc);


% Output:
output = struct('JFz',JFz,'lat',STlat(2:ny-1),'lon',STlon(2:nx-1));
switch nargout
 case 1
  varargout(1) = {output};
end
                                                                                                    gmaze_pv/compute_JFzx.m                                                                             0000644 0023526 0000144 00000011164 10560414775 014524  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [JFzx] = compute_JFzx(SNAPSHOT)
%
% Here we compute the PV flux due to the zonal frictionnal force as
% JFzx = ( TAUx * dSIGMATHETA/dy ) / RHO / EKL
%
% where:
%  TAUx is the surface zonal wind-stress (N/m2)
%  SIGMATHETA is the potential density (kg/m3)
%  RHO is the density (kg/m3)
%  EKL is the Ekman layer depth (m, positive)
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_SIGMATHETA>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_TAUX>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_RHO>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_EKL>.<netcdf_domain>.<netcdf_suff>
% OUTPUT:
% ./netcdf-files/<SNAPSHOT>/JFzx.<netcdf_domain>.<netcdf_suff>
% 
% with netcdf_* as global variables
%
% 06/04/12
% gmaze@mit.edu

function varargout = compute_JFzx(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_TAUX netcdf_SIGMATHETA netcdf_EKL netcdf_RHO
pv_checkpath


% NETCDF file name:
filST  = netcdf_SIGMATHETA;
filTx  = netcdf_TAUX;
filRHO = netcdf_RHO;
filH   = netcdf_EKL;

% Path and extension to find them:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,filST,'.',netcdf_domain,'.',ext);
ncST     = netcdf(ferfile,'nowrite');
[STlon STlat STdpt] = coordfromnc(ncST);

ferfile = strcat(pathname,sla,snapshot,sla,filTx,'.',netcdf_domain,'.',ext);
ncTx    = netcdf(ferfile,'nowrite');

ferfile = strcat(pathname,sla,snapshot,sla,filRHO,'.',netcdf_domain,'.',ext);
ncRHO   = netcdf(ferfile,'nowrite');
RHO     = ncRHO{4}(1,:,:);

ferfile = strcat(pathname,sla,snapshot,sla,filH,'.',netcdf_domain,'.',ext);
ncH     = netcdf(ferfile,'nowrite');
EKL     = ncH{4}(1,:,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First term
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dim:
if toshow, disp('dim'), end
nx = length(STlon) ;
ny = length(STlat) - 1 ;

% Pre-allocate:
if toshow, disp('pre-allocate'), end
dSIGMATHETAdy = zeros(ny-1,nx).*NaN;
dy        = zeros(1,ny).*NaN;
STup      = zeros(1,ny);
STdw      = zeros(1,ny);

% Meridional gradient of SIGMATHETA:
if toshow, disp('grad'), end
% Assuming the grid is regular, dy is independent of x:
dy = m_lldist([1 1]*STlon(1),STlat(1:ny+1) ) ; 
for ix = 1 : nx
  if toshow, disp(strcat(num2str(ix),'/',num2str(nx))), end
  STup  = squeeze(ncST{4}(1,2:ny+1,ix));
  STdw  = squeeze(ncST{4}(1,1:ny,ix));
  dSTdy = ( STup - STdw ) ./ dy;
  % Change horizontal grid point definition to fit with SIGMATHETA:
  dSTdy = ( dSTdy(1:ny-1) + dSTdy(2:ny) )./2; 
  dSIGMATHETAdy(:,ix) = dSTdy;
end %for iy

% Make TAUx having same limits:
TAUx = ncTx{4}(1,2:ny,:);

% Compute first term: TAUx * dSIGMATHETA/dy
JFz_a = TAUx .* dSIGMATHETAdy ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finish ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Then make all terms having same limits:
nx = length(STlon) ;
ny = length(STlat) ;
JFz_a   = squeeze(JFz_a(:,2:nx-1));
delta_e = squeeze(EKL(2:ny-1,2:nx-1));
rho     = squeeze(RHO(2:ny-1,2:nx-1));

% and finish:
JFz = JFz_a./delta_e./rho;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
netfil     = 'JFzx';
units      = 'kg/m3/s2';
ncid       = 'JFzx';
longname   = 'Vertical PV flux due to the zonal frictional force';
uniquename = 'JFzx';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(STlon) ;
ny = length(STlat) ;
nz = 1 ;

nc('X') = nx-2;
nc('Y') = ny-2;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = STlon(2:nx-1);
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = STlat(2:ny-1);
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = STdpt(1);
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = JFz;



%%% Close files:
close(ncST);
close(ncTx);
close(ncRHO);
close(ncH);
close(nc);

% Output:
output = struct('JFzx',JFz,'lat',STlat(2:ny-1),'lon',STlon(2:nx-1));
switch nargout
 case 1
  varargout(1) = {output};
end
                                                                                                                                                                                                                                                                                                                                                                                                            gmaze_pv/compute_MLD.m                                                                              0000644 0023526 0000144 00000010110 10562175511 014237  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [MLD] = compute_MLD(SNAPSHOT)
%
% Here we compute the Mixed Layer Depth as:
% MLD = min depth for which : ST > ST(SSS,SST-0.8,p0)  
%
% where:
%  ST is potential density (kg/m3)
%  SST the Sea Surface Temperature (oC)
%  SSS the Sea Surface Salinity (PSU-35)
%  p0  the Sea Level Pressure (mb)
%  EKL is the Ekman layer depth (m, positive)
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_SIGMATHETA>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_THETA>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_SALTanom>.<netcdf_domain>.<netcdf_suff>
% OUTPUT
% ./netcdf-files/<SNAPSHOT>/<netcdf_MLD>.<netcdf_domain>.<netcdf_suff>
% 
% with netcdf_* as global variables
% netcdf_MLD = 'MLD' by default
%
% Rq: This method leads to a MLD deeper than KPPmld in the middle of the 
% ocean, and shallower along the coast.
%
% 09/20/06
% gmaze@mit.edu

function varargout = compute_MLD(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_SIGMATHETA netcdf_THETA netcdf_SALTanom netcdf_MLD
pv_checkpath


% NETCDF file name:
filST = netcdf_SIGMATHETA;
filT  = netcdf_THETA;
filS  = netcdf_SALTanom;

% Path and extension to find them:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,filST,'.',netcdf_domain,'.',ext);
ncST    = netcdf(ferfile,'nowrite');
ST      = ncST{4}(:,:,:);
[STlon STlat STdpt] = coordfromnc(ncST);

ferfile = strcat(pathname,sla,snapshot,sla,filT,'.',netcdf_domain,'.',ext);
ncT    = netcdf(ferfile,'nowrite');
SST      = ncT{4}(1,:,:);
[Tlon Tlat Tdpt] = coordfromnc(ncT);

ferfile = strcat(pathname,sla,snapshot,sla,filS,'.',netcdf_domain,'.',ext);
ncS   = netcdf(ferfile,'nowrite');
SSS     = ncS{4}(1,:,:);
[Slon Slat Sdpt] = coordfromnc(ncS);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE The Mixed Layer Depth:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('pre-allocate'), end
nx = length(STlon);
ny = length(STlat);
SST08 = SST - 0.8;
SSS   = SSS + 35;
Surfadens08 = densjmd95(SSS,SST08,(0.09998*9.81*Tdpt(1))*ones(ny,nx))-1000;
MLD = zeros(size(ST,2),size(ST,3));

if toshow, disp('get MLD'), end
for iy = 1 : size(ST,2)
  for ix = 1 : size(ST,3)
      mm =  find( squeeze(ST(:,iy,ix)) > Surfadens08(iy,ix) );
      if ~isempty(mm)
        MLD(iy,ix) = STdpt(min(mm));
      end
    %end
  end
end

MLD(isnan(squeeze(ST(1,:,:)))) = NaN;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ensure we have the right sign (positive)
mm = nanmean(nanmean(MLD,1));
if mm <= 0
  MLD = -MLD;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
if ~isempty('netcdf_MLD')
  netfil = netcdf_MLD;
else
  netfil = 'MLD';
end
units      = 'm';
ncid       = 'MLD';
longname   = 'Mixed Layer Depth';
uniquename = 'MLD';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(STlon) ;
ny = length(STlat) ;
nz = 1 ;

nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = STlon;
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = STlat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = STdpt(1);
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = MLD;

nc=close(nc);
close(ncST);
close(ncS);
close(ncT);


% Output:
output = struct('MLD',MLD,'lat',STlat,'lon',STlon);
switch nargout
 case 1
  varargout(1) = {output};
end
                                                                                                                                                                                                                                                                                                                                                                                                                                                        gmaze_pv/compute_QEk.m                                                                              0000644 0023526 0000144 00000007531 10560415154 014316  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [QEk] = compute_QEk(SNAPSHOT)
%
% Here we compute the lateral heat flux induced by Ekman currents
% from JFz, the PV flux induced by frictional forces:
% QEk = - Cw * EKL * JFz / alpha / f
% where:
%  Cw = 4187 J/kg/K is the specific heat of seawater
%  EKL is the Ekman layer depth (m)
%  JFz is the PV flux (kg/m3/s2)
%  alpha = 2.5*E-4 1/K is the thermal expansion coefficient
%  f = 2*OMEGA*sin(LAT) is the Coriolis parameter
%
% This allows a direct comparison with the net surface heat flux Qnet
% which forces the surface Pv flux due to diabatic processes.
%   
% Remind that:
% JFz = ( TAUx * dSIGMATHETA/dy - TAUy * dSIGMATHETA/dx ) / RHO / EKL
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_JFz>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_EKL>.<netcdf_domain>.<netcdf_suff>
% OUPUT:
% ./netcdf-files/<SNAPSHOT>/QEk.<netcdf_domain>.<netcdf_suff>
%
% with netcdf_* as global variables
%
% 06/27/06
% gmaze@mit.edu

function varargout = compute_QEk(snapshot)

global sla toshow
global netcdf_suff netcdf_domain
global netcdf_JFz netcdf_EKL
pv_checkpath


% NETCDF file name:
filJFz  = netcdf_JFz;
filEKL  = netcdf_EKL;

% Path and extension to find them:
pathname = strcat('netcdf-files',sla);
ext = netcdf_suff;

% Load files:
ferfile = strcat(pathname,sla,snapshot,sla,filJFz,'.',netcdf_domain,'.',ext);
ncJFz   = netcdf(ferfile,'nowrite');
JFz     = ncJFz{4}(1,:,:);
[JFzlon JFzlat JFzdpt] = coordfromnc(ncJFz);

ferfile = strcat(pathname,sla,snapshot,sla,filEKL,'.',netcdf_domain,'.',ext);
ncEKL   = netcdf(ferfile,'nowrite');
EKL     = ncEKL{4}(1,:,:);
[EKLlon EKLlat EKLdpt] = coordfromnc(ncEKL);

% Make them having same limits:
% (JFz is defined with first/last points removed from the EKL grid)
nx = length(JFzlon) ;
ny = length(JFzlat) ;
nz = length(JFzdpt) ;
EKL = squeeze(EKL(2:ny+1,2:nx+1));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dim:
if toshow, disp('dim'), end
nx = length(JFzlon) ;
ny = length(JFzlat) ;
nz = length(JFzdpt) ;

% Pre-allocate:
if toshow, disp('pre-allocate'), end
QEk = zeros(nz,ny,nx).*NaN;

% Planetary vorticity:
f = 2*(2*pi/86400)*sin(JFzlat*pi/180);
[a f]=meshgrid(JFzlon,f); clear a c

% Coefficient:
Cw = 4187;
al = 2.5*10^(-4); % Average surface value of alpha
coef = - Cw / al;

% Compute flux:
QEk = coef.* EKL .* JFz ./ f;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow, disp('record'), end

% General informations: 
netfil     = 'QEk';
units      = 'W/m2';
ncid       = 'QEk';
longname   = 'Lateral heat flux induced by Ekman currents';
uniquename = 'QEk';

% Open output file:
nc = netcdf(strcat(pathname,sla,snapshot,sla,netfil,'.',netcdf_domain,'.',ext),'clobber');

% Define axis:
nx = length(JFzlon) ;
ny = length(JFzlat) ;
nz = 1 ;

nc('X') = nx;
nc('Y') = ny;
nc('Z') = nz;
 
nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = JFzlon;
 
nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = JFzlat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = JFzdpt(1);
 
% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = QEk;

nc=close(nc);



% Output:
output = struct('QEk',QEk,'lat',JFzlat,'lon',JFzlon);
switch nargout
 case 1
  varargout(1) = {output};
end
                                                                                                                                                                       gmaze_pv/Contents.m                                                                                 0000644 0023526 0000144 00000013441 10560416053 013673  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % ECCO2: potential vorticity toolbox
%
% This package tries to provide some useful and simple routines to compute, visualize and 
% analyze Potential Vorticity from the global high resolution (1/8deg) simulation of the 
% MITgcm.
% Routines are as general as possible for extended applications, but note that they were
% developped to focus on the Western Atlantic region for the CLIMODE project.
% Enjoy !
%
% gmaze@mit.edu
% Last update: Feb1/2007
%
% ---------------------------------------------------------------------------------------------
% PROGRAMS LIST (NOT A FUNCTIONS):
%
% eg_main_getPV
%                             This program is an example of how to define global setup and 
%                             to launch the PV computing.
% eg_write_bin2cdf_latlongrid_subdomain
%                             This program is an example of how to extract a subdomain from 
%                             a lat/lon grid (1/8) binary file and write it into netcdf. A 
%                             directory is created for each time step.
% eg_write_bin2cdf_csgrid_subdomain
%                             This program is an example of how to extract a subdomain from 
%                             a cube sphere grid (CS510) binary file and write it into netcdf
%                             and lat/lon grid (1/4). A directory is created for each time step.
% eg_write_UVbin2cdf_csgrid_subdomain
%                             Idem, except adapted to U and V fields.
%
% ---------------------------------------------------------------------------------------------
% FUNCTIONS LIST 1: NETCDF FILES DIAGNOSTICS
% From netcdf files contained into SNAPSHOT sub-directory of the
% ./netcdf-files/ home folder, these functions ...
%
% A_compute_potential_density(SNAPSHOT)
%                             Computes potential density SIGMATHETA from potential 
%                             temperature THETA and anomalous salinity SALTanom.
% B_compute_relative_vorticity(SNAPSHOT)
%                             Computes the 3 components of the relative vorticity from the
%                             horizontal flow. Take care to the (U,V) grid !
% C_compute_potential_vorticity(SNAPSHOT,[WANT_SPL_PV])
%                             Computes the potential vorticity field from the relative 
%                             vorticity components and the potential density. Option 
%                             WANT_SPL_PV turned 1 (0 by default) makes the function only 
%                             computing the PV based on the planetary vorticity.
% D_compute_potential_vorticity(SNAPSHOT,[WANT_SPL_PV])
%                             Multiplies the potential vorticity computed with 
%                             C_COMPUTE_POTENTIAL_VORTICITY by the coefficient: -1/RHO
%                             Optional flag WANTSPLPV is turned to 0 by default. Turn it to 1
%                             if the PV computed was the simple one (f.dSIGMATHETA/dz). It's 
%                             needed for the output netcdf file informations.
% compute_JBz(SNAPSHOT)
%                             Computes the surface PV flux due to diabatic processes.
% compute_JFz(SNAPSHOT)
%                             Computes the surface PV flux due to frictionnal forces.
% compute_density(SNAPSHOT)
%                             Computes density RHO from potential temperature THETA 
%                             and anomalous salinity SALTanom.
% compute_alpha(SNAPSHOT)
%                             Computes the thermal expansion coefficient ALPHA from potential 
%                             temperature THETA and salinity anomaly SALTanom.
% compute_QEk(SNAPSHOT)
%                             Computes QEk, the lateral heat flux induced by Ekman currents
%                             from JFz, the PV flux induced by frictional forces.
% compute_EKL(SNAPSHOT)
%                             Compute the Ekman Layer Depth from the wind stress and the density
%                             fields.
% compute_MLD(SNAPSHOT)
%                             Compute the Mixed Layer Depth from the SST, SSS and potential
%                             density fields.
%
% ---------------------------------------------------------------------------------------------
% FUNCTIONS LIST 2: ANALYSIS FUNCTIONS
%
% volbet2iso(TRACER,LIMITS,DEPTH,LAT,LONG)
%                             This function computes the volume embedded between two
%                             iso-TRACER values and limited eastward, westward and southward
%                             by fixed limits.
% surfbet2outcrops(TRACER,LIMITS,LAT,LONG)
%                             This function computes the horizontal surface limited
%                             by two outcrops of a tracer.
% intbet2outcrops(TRACER,LIMITS,LAT,LONG)
%                             This function computes the horizontal surface integral
%                             of the field TRACER on the area limited by two outcrops.
% subfct_getisoS(TRACER,ISO)
%                             This function determines the iso-surface ISO of the 
%                             3D field TRACER(Z,Y,X).
%
% ---------------------------------------------------------------------------------------------
% LOWER LEVEL AND SUB-FUNCTIONS LIST:
%
% pv_checkpath
%                             This function, systematicaly called by the others, ensures that 
%                             all needed sub-directories of the package are in the path.
%
% ---------------------------------------------------------------------------------------------
% PS:
%
% > Functions name are case sensitive.
% > See sub-directory "subfct" for further functions.
% > Following packages are required: 
%   M_MAP:    http://www.eos.ubc.ca/~rich/map.html
%   SEAWATER: http://www.marine.csiro.au/datacentre/processing.htm
%
% ---------------------------------------------------------------------------------------------
%
                                                                                                                                                                                                                               gmaze_pv/D_compute_potential_vorticity.m                                                            0000644 0023526 0000144 00000010353 10560414131 020202  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [Q] = D_compute_potential_vorticity(SNAPSHOT,[WANTSPLPV])
%
% For a time snapshot, this program multiplies the potential
% vorticity computed with C_COMPUTE_POTENTIAL_VORTICITY by the
% coefficient: -1/RHO
% Optional flag WANTSPLPV is turn to 0 by default. Turn it to 1
% if the PV computed is the simple one (f.dSIGMATHETA/dz). It's 
% needed for the output netcdf file informations.
% 
% CAUTION:
%% If all the PV computing procedure has been performed with routines
%% from the package, the PV field has less points than the RHO one, exactly
%% first and last in all directions have to be removed from RHO.
%
% Files names are:
% INPUT:
% ./netcdf-files/<SNAPSHOT>/<netcdf_RHO>.<netcdf_domain>.<netcdf_suff>
% ./netcdf-files/<SNAPSHOT>/<netcdf_PV>.<netcdf_domain>.<netcdf_suff>
% OUPUT:
% ./netcdf-files/<SNAPSHOT>/PV.<netcdf_domain>.<netcdf_suff>
% or 
% ./netcdf-files/<SNAPSHOT>/splPV.<netcdf_domain>.<netcdf_suff>
%
% 06/21/2006
% gmaze@mit.edu
%

  
function varargout = D_compute_potential_vorticity(snapshot,varargin)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global sla netcdf_RHO netcdf_PV netcdf_domain netcdf_suff
pv_checkpath

%% Flags to choose which term to compute (by default, all):
FLpv3 = 1;
if nargin==2  % case of optional flag presents:
  if varargin{1}(1) == 1 % Case of the simple PV:
    FLpv3 = 0;
  end
end %if

%% PV and RHO netcdf-files:
filPV  = strcat(netcdf_PV ,'.',netcdf_domain);
filRHO = strcat(netcdf_RHO,'.',netcdf_domain);

%% Path and extension to find them:
pathname = strcat('netcdf-files',sla,snapshot);
ext      = strcat('.',netcdf_suff);

%% Load netcdf files:
ferfile = strcat(pathname,sla,filPV,ext);
ncPV    = netcdf(ferfile,'nowrite');
[PV_lon PV_lat PV_dpt] = coordfromnc(ncPV);

ferfile = strcat(pathname,sla,filRHO,ext);
ncRHO   = netcdf(ferfile,'nowrite');
[RHO_lon RHO_lat RHO_dpt] = coordfromnc(ncRHO);

%% Flags:
global toshow % Turn to 1 to follow the computing process



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Apply the coefficient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Pre-allocate:
if toshow,disp('Pre-allocate');end
nx = length(PV_lon);
ny = length(PV_lat);
nz = length(PV_dpt);
PV = zeros(nz,ny,nx).*NaN;

%% Apply:
if toshow,disp('Multiplying PV field by -1/RHO'),end
PV =  - ncPV{4}(:,:,:) ./ ncRHO{4}(2:nz+1,2:ny+1,2:nx+1) ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if toshow,disp('Now reccording PV file ...'),end

% General informations: 
%ncclose(ncPV);

if FLpv3 == 1
  netfil     = strcat('PV','.',netcdf_domain,'.',netcdf_suff);
  units      = '1/s/m';
  ncid       = 'PV';
  longname   = 'Potential vorticity';
  uniquename = 'potential_vorticity';
else
  netfil     = strcat('splPV','.',netcdf_domain,'.',netcdf_suff);
  units      = '1/s/m';
  ncid       = 'splPV';
  longname   = 'Simple Potential vorticity';
  uniquename = 'simple_potential_vorticity';
end %if  

% Open output file:
nc = netcdf(strcat(pathname,sla,netfil),'clobber');

% Define axis:
nc('X') = length(PV_lon);
nc('Y') = length(PV_lat);
nc('Z') = length(PV_dpt);

nc{'X'} = 'X';
nc{'Y'} = 'Y';
nc{'Z'} = 'Z';

nc{'X'}            = ncfloat('X');
nc{'X'}.uniquename = ncchar('X');
nc{'X'}.long_name  = ncchar('longitude');
nc{'X'}.gridtype   = nclong(0);
nc{'X'}.units      = ncchar('degrees_east');
nc{'X'}(:)         = PV_lon;

nc{'Y'}            = ncfloat('Y'); 
nc{'Y'}.uniquename = ncchar('Y');
nc{'Y'}.long_name  = ncchar('latitude');
nc{'Y'}.gridtype   = nclong(0);
nc{'Y'}.units      = ncchar('degrees_north');
nc{'Y'}(:)         = PV_lat;
 
nc{'Z'}            = ncfloat('Z');
nc{'Z'}.uniquename = ncchar('Z');
nc{'Z'}.long_name  = ncchar('depth');
nc{'Z'}.gridtype   = nclong(0);
nc{'Z'}.units      = ncchar('m');
nc{'Z'}(:)         = PV_dpt;

% And main field:
nc{ncid}               = ncfloat('Z', 'Y', 'X'); 
nc{ncid}.units         = ncchar(units);
nc{ncid}.missing_value = ncfloat(NaN);
nc{ncid}.FillValue_    = ncfloat(NaN);
nc{ncid}.longname      = ncchar(longname);
nc{ncid}.uniquename    = ncchar(uniquename);
nc{ncid}(:,:,:)        = PV;

nc=close(nc);
close(ncPV);
close(ncRHO);

% Outputs:
OUT = struct('PV',PV,'dpt',PV_dpt,'lat',PV_lat,'lon',PV_lon);
switch nargout
 case 1
  varargout(1) = {OUT};
end
                                                                                                                                                                                                                                                                                     gmaze_pv/diagWALIN.m                                                                                0000644 0023526 0000144 00000014772 10642604460 013607  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % [F,A,D,CROP] = diagWALIN(FLAG,C1,C2,Qnet,Snet,Classes,lon,lat,dA)
% 
% DESCRIPTION:
% Compute the transformation rate of a surface outcrop class (potential
% density or SST) from surface net heat flux Qnet and salt flux Snet
% according to the Walin theory.
%
% INPUTS: 
% FLAG    : Can either be: 0, 1 or 2
%           0: Outcrop field is surface potential density computed 
%              from C1=SST and C2=SSS
%           1: Outcrop field is surface potential density given by C1
%           2: Outcrop field is SST and potential density is computed 
%              from C1=SST and C2=SSS
% C1,C2   : Depends on option FLAG:
%           - FLAG = 0 : 
%                        C1 : Sea surface temperature (degC) 
%                        C2 : Sea surface salinity (PSU)
%           - FLAG = 1 : 
%                        C1 : Surface potential density (kg/m3) 
%                        C2 : Not used
%           - FLAG = 2 : 
%                        C1 : Sea surface temperature (degC) 
%                        C2 : Sea surface salinity (PSU)
% Qnet    : Downward net surface heat flux (W/m2)
% Snet    : Downward net surface salt flux (kg/m2/s) -> 
%           ie, Snet = rho*beta*SSS*(E-P)
% Classes : Range of outcrops to explore (eg: [20:.1:30] for potential density)
% lon,lat : axis
% dA      : Matrix of grid surface elements (m2) centered in (lon,lat) 
%
%
% OUTPUTS:
% F(3,:)    : Transformation rate (m3/s) (from 1:Qnet, 2:Snet and 3:Total)
% A         : Surface of each outcrops
% D(3,:,:)  : Maps of density flux (kg/m2/s) from 1:Qnet, 2:Snet and 3:Total
% CROP(:,:) : Map of the surface field used to compute outcrop's contours
%
%
% NOTES:
% - Fields are of the format: C(LAT,LON)
% - The potential density is computed with the equation of state routine from
%   the MITgcm called densjmd95.m 
%   (see: http://mitgcm.org/cgi-bin/viewcvs.cgi/MITgcm_contrib/gmaze_pv/subfct/densjmd95.m)
% - Snet may be filled of NaN if not available, its F component won't computed
%
%
% AUTHOR: 
% Guillaume Maze / MIT 2006
% 
% HISTORY:
% - Revised: 06/28/2007
%            * Add option do directly give the pot. density as input
%            * Add options do take SST as outcrop 
% - Created: 06/22/2007
%
% REFERENCES: 
% Walin G. 1982: On the relation between sea-surface 
% heat flow and thermal circulation in the ocean. Tellus N24
%

% The routine is not optimized for speed but for clarity, that's why we
% compute buoyancy fluxes, etc...
%
% TO DO: 
% - Fix signs in density fluxes to be correct albeit consistent with F right now
% - Create options for non regular CLASS
% - Create options to also compute the formation rate M
% - Create options to compute an error bar
% - Create check of inputs section

function varargout = diagWALIN(FLAG,C1,C2,QNET,SNET,CLASS,lon,lat,dA);



% 0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREPROC
% Variables:
nlat = size(C1,1);
nlon = size(C1,2);
CLASS = CLASS(:);
  
% Determine surface fields from which we'll take outcrops contours:
switch FLAG
  
 case {0,2} % Need to compute SIGMA THETA
  SST = C1;
  SSS = C2;
  ST = densjmd95(SSS,SST,zeros(nlat,nlon)) - 1000;  % Real surface (depth = 0)
  %dpt = -5; ST = densjmd95(SSS,SST,(0.09998*9.81*dpt)*ones(nlat,nlon)) - 1000; % Model surface
  if FLAG == 0     % Outcrop is SIGMA THETA:
     OUTCROP = ST;
  elseif FLAG == 2 % Outcrop is SST:
     OUTCROP = SST;
  end
  
 case 1
  ST = C1; % Potential density
  OUTCROP = ST;
end
  
% Create a flag if we don't find salt flux:
if length(find(isnan(SNET)==1)) == nlat*nlon
  do_ep = 0;
else
  do_ep = 1;
end

% Physical constants:
g = 9.81;        % Gravity (m/s2)
Cp = 3994;       % Specific heat of sea water (J/K/kg)
rho0 = 1035;     % Density of reference (kg/m3)
rho  = ST+1000;  % Density (kg/m3)
		 % Thermal expansion coefficient (1/K)
if exist('SST') & exist('SSS') 
  alpha = sw_alpha(SSS,SST,zeros(nlat,nlon));
else
  alpha = 2.*1e-4; 
end


% 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% BUOYANCY FLUX: b
% The buoyancy flux (m/s2*m/s=m2/s3) is computed as:
% b = g/rho*( alpha/Cp*QNET - SNET )
% b = g/rho*alpha/Cp*QNET - g/rho*SNET
% b = b_hf + b_ep
% QNET the net heat flux (W/m2) and SNET the net salt flux (kg/m2/s) 
              b_hf =  g.*alpha./Cp.*QNET./rho;
if do_ep==1,  b_ep = -g*SNET./rho; else b_ep = zeros(nlat,nlon); end
                 b = b_hf + do_ep*b_ep;


% 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DENSITY FLUX: bd
% Buoyancy flux is transformed into density flux (kg/m3*m/s = kg/m2/s):
% bd = - rho/g * b
% with b the buoyancy flux
             bd_hf = - rho/g.*b_hf; 
             bd_ep = - rho/g.*b_ep;
             bd    = - rho/g.*b;


% 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NET MASS FLUX INTEGRATED OVER OUTCROPS: Bd
% The amount of mass water flux over an outcrop is computed as:
% Bd = SUM_ij bd(i,j)*dA(i,j)*MASK(i,j,OUTCROP)
% with MASK(i,j,OUTCROP) = 1 where  OUTCROP(i,j)-dC/2 <=  OUTCROP(i,j) < OUTCROP(i,j)+dC/2
%                        = 0 otherwise
% Outcrops are defined with an increment of:
dCROP = diff(CLASS(1:2));

switch FLAG
 case {0,1}, coef = 1;                 % Potential density as outcrops
 case 2,     coef = 1./(alpha.*rho0);  % SST as outcrops
end %switch

% Surface integral:
for iC = 1 : length(CLASS)
  CROPc  = CLASS(iC);
  mask   = zeros(nlat,nlon);
  mask(find( (CROPc-dCROP/2 <= OUTCROP) & (OUTCROP < CROPc+dCROP/2) )) = 1;
               Bd_hf(iC) = nansum(nansum(dA.*mask.*bd_hf.*coef,1),2);
               Bd_ep(iC) = nansum(nansum(dA.*mask.*bd_ep.*coef,1),2);
                  Bd(iC) = nansum(nansum(dA.*mask.*bd.*coef,1),2);
		  AA(iC) = nansum(nansum(dA.*mask,1),2);
end %for iC


% 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TRANSFORMATION RATE: F
% F is defined as the convergence/divergence of the integrated mass flux Bd.
% F = Bd(CROP) / dCROP
% where Bd is the mass flux over an outcrop.
             F_hf = Bd_hf./dCROP;
             F_ep = Bd_ep./dCROP; 
             F    = Bd./dCROP;


% 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUTS
% Transformation rate:
TRANSFORM_RATE(1,:) = F_hf;
TRANSFORM_RATE(2,:) = F_ep;
TRANSFORM_RATE(3,:) = F;	     

% Density flux:
DENSITY_FLUX(1,:,:) = bd_hf;
DENSITY_FLUX(2,:,:) = bd_ep;
DENSITY_FLUX(3,:,:) = bd;

switch nargout
 case 1
  varargout(1) = {TRANSFORM_RATE};
 case 2
  varargout(1) = {TRANSFORM_RATE};
  varargout(2) = {AA};
 case 3
  varargout(1) = {TRANSFORM_RATE};
  varargout(2) = {AA};
  varargout(3) = {DENSITY_FLUX};
 case 4
  varargout(1) = {TRANSFORM_RATE};
  varargout(2) = {AA};
  varargout(3) = {DENSITY_FLUX};
  varargout(4) = {OUTCROP};
end %switch
      gmaze_pv/eg_main_getPV.m                                                                            0000644 0023526 0000144 00000011111 10557734746 014614  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % 
% THIS IS NOT A FUNCTION !
%
% Here is the main program to compute the potential vorticity Q
% from the flow (UVEL,VVEL), potential temperature (THETA) and
% salinity (SALTanom), given snapshot fields.
% 3 steps to do it:
%   1- compute the potential density SIGMATHETA (also called ST)
%      from THETA and SALTanom: 
%      ST = SIGMA(S,THETA,p=0)
%   2- compute the 3D relative vorticity field OMEGA (called O)
%      without vertical velocity terms:
%      O = ( -dVdz ; dUdz ; dVdx - dUdy )
%   3- compute the potential vorticity Q:
%      Q = Ox.dSTdx + Oy.dSTdy + (f+Oz).dSTdz
%      (note that we only add the planetary vorticity at this last
%      step).
%      It's also possible to add a real last step 4 to compute PV as:
%      Q = -1/RHO * [Ox.dSTdx + Oy.dSTdy + (f+Oz).dSTdz]
%      Note that in this case, program loads the PV output from the
%      routine C_compute_potential_vorticity (step 3) and simply multiply 
%      it by: -1/RHO.
%      RHO may be computed with the routine compute_density.m
%
%
% Input files are supposed to be in a subdirectory called: 
% ./netcdf-files/<snapshot>/
%
% File names id are stored in global variables:
%    netcdf_UVEL, netcdf_VVEL, netcdf_THETA, netcdf_SALTanom
% with the format:
%    netcdf_<ID>.<netcdf_domain>.<netcdf_suff>
% where netcdf_domain and netcdf_suff are also in global
% THE DOT IS ADDED IN SUB-PROG, SO AVOID IT IN DEFINITIONS
%
% Note that Q is not initialy defined with the ratio by -RHO.
%
% A simple potential vorticity (splQ) computing is also available.
% It is defined as: splQ = f. dSIGMATHETA/dz
% 
% 30Jan/2007
% gmaze@mit.edu
%
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   SETUP:
pv_checkpath


% File's name:
global netcdf_UVEL netcdf_VVEL netcdf_THETA 
global netcdf_SALTanom is_SALTanom
global netcdf_TAUX netcdf_TAUY netcdf_SIGMATHETA 
global netcdf_RHO netcdf_EKL netcdf_Qnet netcdf_MLD
global netcdf_JFz netcdf_JBz
global netcdf_suff netcdf_domain sla
netcdf_UVEL     = 'UVEL';
netcdf_VVEL     = 'VVEL';
netcdf_THETA    = 'THETA';
netcdf_SALTanom = 'SALTanom'; is_SALTanom = 1;
netcdf_TAUX     = 'TAUX';
netcdf_TAUY     = 'TAUY';
netcdf_SIGMATHETA = 'SIGMATHETA';
netcdf_RHO      = 'RHO';
netcdf_EKL      = 'EKL';
netcdf_MLD      = 'KPPmld'; %netcdf_MLD      = 'MLD';
netcdf_Qnet     = 'TFLUX';
netcdf_JFz      = 'JFz'; 
netcdf_JBz      = 'JBz'; 
netcdf_suff     = 'nc';
netcdf_domain   = 'north_atlantic'; % Must not be empty !



% FLAGS:
% Turn 0/1 the following flag to determine which PV to compute:
wantsplPV = 0; % (turn 1 for simple PV computing)
% Turn 0/1 this flag to get online computing informations:
global toshow
toshow = 0;

% Get date list:
ll = dir(strcat('netcdf-files',sla));
nt = 0;
for il = 1 : size(ll,1)
  if ll(il).isdir & findstr(ll(il).name,'00')
    nt = nt + 1;
    list(nt).name = ll(il).name;
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TIME LOOP
for it = 1 : nt
  % Files are looked for in subdirectory defined by: ./netcdf-files/<snapshot>/
  snapshot = list(it).name;
  disp('********************************************************')
  disp('********************************************************')
  disp(snapshot)
  disp('********************************************************')
  disp('********************************************************')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   COMPUTING PV:
% STEP 1:
% Output netcdf file is:
%       ./netcdf-files/<snapshot>/SIGMATHETA.<netcdf_domain>.<netcdf_suff>
A_compute_potential_density(snapshot)
compute_density(snapshot)


% STEP 2:
% Output netcdf files are:
%       ./netcdf-files/<snapshot>/OMEGAX.<netcdf_domain>.<netcdf_suff>
%       ./netcdf-files/<snapshot>/OMEGAY.<netcdf_domain>.<netcdf_suff>
%       ./netcdf-files/<snapshot>/ZETA.<netcdf_domain>.<netcdf_suff>
% No interest for the a splPV computing
if ~wantsplPV
   B_compute_relative_vorticity(snapshot)
end %if

% STEP 3:
% Output netcdf file is:
%       ./netcdf-files/<snapshot>/PV.<netcdf_domain>.<netcdf_suff>
C_compute_potential_vorticity(snapshot,wantsplPV)

% STEP 4:
% Output netcdf file is (replace last one):
%       ./netcdf-files/<snapshot>/PV.<netcdf_domain>.<netcdf_suff>
global netcdf_PV
if wantsplPV == 1
  netcdf_PV = 'splPV';
else
  netcdf_PV = 'PV';
end %if
D_compute_potential_vorticity(snapshot,wantsplPV)


% OTHER computations:
if 0
 compute_alpha(snapshot)
 compute_MLD(snapshot)
 compute_EKL(snapshot)
 compute_JFz(snapshot);
 compute_JBz(snapshot);
 compute_Qek(snapshot);
end %if 1/0


fclose('all');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THAT'S IT !
end %for it


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THAT'S IT !

% Keep clean workspace:
clear wantsplPV toshow netcdf_*
clear global wantsplPV toshow netcdf_*
                                                                                                                                                                                                                                                                                                                                                                                                                                                       gmaze_pv/eg_write_bin2cdf_csgrid_subdomain.m                                                        0000644 0023526 0000144 00000017073 10557736662 020714  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % Script to extract a subdomain from a CS510 simulation
% and write in netCDF format on a regular lat/lon grid (1/4)
%
clear
global sla
pv_checkpath


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Global setup:
% Restrict global domain to:
subdomain = 3; % North Atlantic

% Path to find input binary Cube sphere files:
pathi = './bin_cube49';

% Path where the netcdf outputs will be stored:
patho = './ecco2_cube49_netcdf';
patho = strcat(patho,sla,'monthly');
%patho = strcat(patho,sla,'six_hourly');

% Time step (for date conversion):
dt = 1200;

% Variables to analyse (index into otab):
otab = cs510grid_outputs_table; % from the 1/8 latlon definition
wvar = [];
dimen = 3;
switch dimen
  case 3 % 3D fields:
    %wvar = [wvar 34]; % THETA
    %wvar = [wvar 31]; % RHOAnoma
    %wvar = [wvar 33]; % SALTanom
  case 2 % 2D fields:
    wvar = [wvar 23]; % TFLUX
    %wvar = [wvar 20]; % SST
    %wvar = [wvar 19]; % SSS
end %switch number of dimensions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pre-process
% Get the grid:
path_grid = './grid';
XC = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'XC')),1,'float32');
YC = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'YC')),1,'float32');
XG = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'XG')),1,'float32');
YG = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'YG')),1,'float32');
GRID_125;
ZC = - [0 cumsum(thk125(1:length(thk125)-1))];
clear dpt125 lat125 lon125 thk125

% How to move to a lat/lon grid:
% CS510 is about 22km average resolution, ie: 1/4 degree
XI =   -180 : 1/4 : 180; 
YI = -90 : 1/4 : 90;
ZI = ZC;
if ~exist('CS510_to_LATLON025.mat','file')
   del = cube2latlon_preprocess(XC,YC,XI,YI);
   save('CS510_to_LATLON025.mat','XI','YI','XC','YC','del','-v6');
else
   load('CS510_to_LATLON025.mat')
end

% Set subrange - Longitude given as degrees east 
% (exact values come from the 1/8 lat-lon grid)
switch subdomain
  case 3
   sub_name = 'north_atlantic';
   lonmin = 276.0625;
   lonmax = 359.9375;
   latmin = 12.0975;
   latmax = 53.2011;
   depmin = 1;    % !!! indices
   depmax = 29;   % !!! indices
   if dimen == 3, depmax = 29,
   else, depmax = 1;end
   LIMITS = [lonmin lonmax latmin latmax depmin depmax]
   if 0
     m_proj('mercator','long',[270 365],'lat',[0 60]);
     clf;hold on;m_coast;m_grid;
     m_line(LIMITS([1 2 2 1 1]),LIMITS([3 3 4 4 3]),'color','k','linewidth',2);
     title(sub_name);
   end %if 1/0
end

% Get subdomain horizontal axis:
xi = XI(max(find(XI<=LIMITS(1))):max(find(XI<=LIMITS(2))));
yi = YI(max(find(YI<=LIMITS(3))):max(find(YI<=LIMITS(4))));
zi = ZI(LIMITS(5):LIMITS(6));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Loop over variables to read
for i = 1 : length(wvar)
 ifield = wvar(i);
 fil = otab{ifield,1};
 
%                                                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get info over the time loop
 % Get the file list:
 fild = fil; % Insert condition here for special files:
 if ifield == 23 & findstr(patho,'six')
    fild = 'surForcT';
    fil  = 'surForcT';
 end   
 l = dir(strcat(pathi,sla,fild));
 it = 0;
 clear ll
 for il = 1 : size(l,1)
   if ~l(il).isdir & findstr(l(il).name,strcat(fil,'.')) % is'it the file type we want ?
     it = it + 1;
     ll(it).name = l(il).name;
   end %if
 end %for il
 % Create the timetable:
 for il = 1 : size(ll,2)
   filin = ll(il).name;
   % Now extract the stepnum from : %s.%10.10d.data
   ic = findstr(filin,fil)+length(fil)+1; i = 1; clear stepnum
   while filin(ic) ~= '.'
      stepnum(i) = filin(ic); i = i + 1; ic = ic + 1;
   end
   ID = str2num(stepnum);
   TIME(il,:) = datestr(datenum(1992,1,1)+ID*dt/60/60/24,'yyyymmddHHMM');
 end
 nt = size(TIME,1);
 
%                                                 %%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Loop over time
 for it = 1 : nt
   snapshot = TIME(it,:);
   ID = 60*60*24/dt*( datenum(snapshot,'yyyymmddHHMM') - datenum(1992,1,1) );
   filin = ll(it).name;
   disp('')
   disp(strcat('Processing: ',fil,'//',snapshot))
   dirout = strcat(patho,sla,TIME(it,:),sla);
   filout = sprintf('%s.%s.nc',otab{ifield,1},sub_name);
   
   if ~exist(strcat(dirout,sla,filout),'file') % File already exists ?
   
%%%% READ THE FILE
   switch otab{ifield,6}
    case 4, flt = 'float32';
    case 8, flt = 'float64';
   end
   t0 = clock;
   if findstr(filin,'.gz') % Gunzip file, special care !     
      disp('|----> Find a file with gz extension, work on uncompressed file ...')
      
      % 1: copy the filename with it path into gunzip_1_file.txt
      fid1 = fopen('gunzip_1_file.txt','w');
      fprintf(fid1,'%s',strcat(pathi,sla,fild,sla,filin));fclose(fid1);

      % 2: uncompress the file into a temporary folder:
      disp('|------> uncompressing the file ...')
      ! ./gunzip_1_file.bat
      disp(strcat('|--------: ',num2str(etime(t0,clock))))
      
      % 3: Read the uncompress file:
      disp('|--> reading it ...')
      C = readrec_cs510(strcat('gunzip_1_file',sla,'tempo.data'),LIMITS(6),flt);
      disp(strcat('|----: ',num2str(etime(t0,clock))))
      
      % 4: Suppress it
      ! \rm ./gunzip_1_file/tempo.data
      
   else % Simply read the file:
      disp('|--> reading it ...')
      C = readrec_cs510(strcat(pathi,sla,fild,sla,filin),LIMITS(6),flt);
      disp(strcat('|----: ',num2str(etime(t0,clock))))
   end
   
%%%% RESTRICT TO SUBDOMAIN
   disp('|--> get subdomain ...')
   % Restrict vertical to subdomain:
   if LIMITS(5) ~= 1
      disp('|----> vertical ...');
      C = C(:,:,LIMITS(5):end);
   end
   % Clean the field:
   C(find(C==0)) = NaN; 
   % Move the field into lat/lon grid:
   disp('|----> Move to lat/lon grid ...');
   C = cube2latlon_fast(del,C);
   % And then restrict horizontal to subdomain: 
   disp('|----> horizontal ...');  
   C = C(max(find(XI<=LIMITS(1))):max(find(XI<=LIMITS(2))),...
	 max(find(YI<=LIMITS(3))):max(find(YI<=LIMITS(4))),:);
   
   
%%%% RECORD
   disp('|--> record netcdf file ...')
   fid1 = fopen('inprogress.txt','w');
   fprintf(fid1,'%s',strcat(dirout,sla,filout));fclose(fid1);
   
   if 1 % Realy want to record ?
     
   if ~exist(dirout,'dir')
       mkdir(dirout);
   end
   
   
     nc = netcdf('inprogress.nc','clobber');

     nc('X') = length(xi);
     nc('Y') = length(yi);
     nc('Z') = length(zi);

     nc{'X'}='X';
     nc{'Y'}='Y';
     nc{'Z'}='Z';

     nc{'X'}.uniquename='X';
     nc{'X'}.long_name='longitude';
     nc{'X'}.gridtype=ncint(0);
     nc{'X'}.units='degrees_east';
     nc{'X'}(:) = xi;

     nc{'Y'}.uniquename='Y';
     nc{'Y'}.long_name='latitude';
     nc{'Y'}.gridtype=ncint(0);
     nc{'Y'}.units='degrees_north';
     nc{'Y'}(:) = yi;

     nc{'Z'}.uniquename='Z';
     nc{'Z'}.long_name='depth';
     nc{'Z'}.gridtype=ncint(0);
     nc{'Z'}.units='m';
     nc{'Z'}(:) = zi;

     ncid = fil;
     nc{ncid}={'Z' 'Y' 'X'};
     nc{ncid}.missing_value = ncdouble(NaN);
     nc{ncid}.FillValue_ = ncdouble(0.0);
     nc{ncid}(:,:,:) = permute(C,[3 2 1]);
     nc{ncid}.units = otab{ifield,5};

     close(nc);
     ! ./inprogress.bat
     
   end %if 1/0 want to record ?
   disp(strcat('|--: ',num2str(etime(t0,clock))))
   
   else
     disp(strcat('|--> Skip file (already done):',dirout,sla,filout))
   end %if %file exist
 
 end %for it
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END Loop over time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
end %if it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END Loop over variables to read
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     gmaze_pv/eg_write_bin2cdf_latlongrid_subdomain.m                                                    0000644 0023526 0000144 00000011470 10557736437 021573  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %  Script to extract and write in netCDF format a subdomain
%  from the 1.8 global run 
%
clear
global sla
pv_checkpath

% Load grid
GRID_125

% Load list of all outputs
otab = latlon8grid_outputs_table;

% Setup standard grid variables
lon_c = lon125;
lon_u = [lon125(1)-360+lon125(end) (lon125(2:end)+lon125(1:end-1))/2];
lat_c = lat125;
lat_v = [lat125(1)-(lat125(2)-lat125(1))/2 (lat125(1:end-1)+lat125(2:end))/2];
z_c = (cumsum(thk125)-thk125/2);
z_w = [0 cumsum(thk125(1:end-1))];


% Set subrange - Longitude given as degrees east
subdomain = 4;

switch subdomain
  case 1
sub_name = 'western_north_atlantic';
lonmin = lon125(2209)-180;
lonmax = lon125(2497-1)-180; 
latmin = lat125(1225); 
latmax = lat125(1497-1); 
depmin = min(z_w); 
depmax = z_c(29);
m_proj('mercator','long',[270 365],'lat',[0 60]);
%clf;hold on;m_coast;m_grid;
LIMITS = [lonmin+180 lonmax+180 latmin latmax depmin depmax]
%m_line(LIMITS([1 2 2 1 1]),LIMITS([3 3 4 4 3]),'color','r','linewidth',2);
%title(sub_name);

  case 3
sub_name = 'north_atlantic';
lonmin = lon125(2209)-180;
lonmax = lon125(2881-1)-180; 
latmin = lat125(1157); 
latmax = lat125(1565-1); 
depmin = min(z_w);
depmax = z_c(29);
m_proj('mercator','long',[270 365],'lat',[0 60]);
clf;hold on;m_coast;m_grid;
LIMITS = [lonmin+180 lonmax+180 latmin latmax depmin depmax]
m_line(LIMITS([1 2 2 1 1]),LIMITS([3 3 4 4 3]),'color','k','linewidth',2);
title(sub_name);

  case 4
sub_name = 'global';
lonmin = lon125(1)-180;
lonmax = lon125(2881-1)-180; 
latmin = lat125(1); 
latmax = lat125(2177-1); 
depmin = min(z_w);
depmax = z_c(29); depmax = z_w(2);
m_proj('mercator','long',[0 360],'lat',[-90 90]);
clf;hold on;m_coast;m_grid;
LIMITS = [lonmin+180 lonmax+180 latmin latmax depmin depmax]
m_line(LIMITS([1 2 2 1 1]),LIMITS([3 3 4 4 3]),'color','k','linewidth',2);
title(sub_name);


  case 10
sub_name = 'KE';
lonmin = lon125(961)-180;
lonmax = lon125(1601-1)-180; 
latmin = lat125(1140); 
latmax = lat125(1523-1); 
depmin = min(z_w);
depmax = z_c(25);
m_proj('mercator','long',[0 360],'lat',[-90 90]);
%clf;hold on;m_coast;m_grid;
LIMITS = [lonmin+180 lonmax+180 latmin latmax depmin depmax]
%m_line(LIMITS([1 2 2 1 1]),LIMITS([3 3 4 4 3]),'color','k','linewidth',2);
%title(sub_name);


end

%refresh

% Path of the directory to find input binary files:
pathi = 'ecco2_cycle1_bin/';

% Path where the netcdf outputs will be stored:
patho = './ecco2_cycle1_netcdf/monthly/';
%patho = './ecco2_cycle1_netcdf/six_hourly/';

% Variables to analyse (index into otab):
wvar = [];
% 3D fields:
wvar = [wvar 34]; % THETA
wvar = [wvar 35]; % THETASQ
%wvar = [wvar 33]; % SALTanom
%wvar = [wvar 47]; % VVEL
%wvar = [wvar 31]; % RHOAnoma



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1 : length(wvar)
 ifield = wvar(i);
 fil = otab{ifield,1};
 l = dir(strcat(pathi,fil,sla));
 if ifield == 33, 
   l = dir(strcat(pathi,'SALT',sla));
 end
 if ifield == 35, 
   l = dir(strcat(pathi,'THETA',sla));
 end
 if ifield == 31, 
   l = dir(strcat(pathi,'RHO',sla));
 end
 it = 0;
 clear ll
 for il = 1 : size(l,1)
   if ~l(il).isdir & findstr(l(il).name,strcat(fil,'.')) % is'it the file type we want ?
     it = it + 1;
     ll(it).name = l(il).name;
   end %if
 end %for il
 
 if it ~= 0 % if we found any files to compute:
   
 % Create the timetable:
 for il = 1 : size(ll,2)
   filinprog = ll(il).name;
   stepnum=str2num(filinprog(findstr(filinprog,fil)+length(fil)+1:length(filinprog)- ...
			   length('.data')));
   TIME(il,:) = dtecco2(stepnum,0);
 end
   
 % Translate files:
 for il = 1 : size(ll,2)
 
 filinprog = ll(il).name;
 stepnum=str2num(filinprog(findstr(filinprog,fil)+length(fil)+1:length(filinprog)- ...
			   length('.data')));
 ID = datenum(1992,1,1)+stepnum*300/60/60/24;
 dte = datestr(ID,'yyyymmddHHMM');
 disp(strcat(fil,'->',datestr(ID,'yyyy/mm/dd/HH:MM'),'== Recorded in ==>',TIME(il,:)));
 dirout = strcat(patho,sla,TIME(il,:));
 
 if 1 % Want to record ?
 if ~exist(dirout,'dir')
     mkdir(dirout);
 end
 pathname = strcat(pathi,fil,sla);
 if ifield == 33, 
   pathname = strcat(pathi,'SALT',sla);
 end
 if ifield == 35, 
   pathname = strcat(pathi,'THETA',sla);
 end
 if ifield == 31, 
   pathname = strcat(pathi,'RHO',sla);
 end
 if ~exist(strcat(dirout,sla,sprintf('%s.%s.nc',otab{ifield,1},sub_name)),'file')
 %if 1
 latlon2ingrid_netcdf(pathname,strcat(dirout,sla),...
		    stepnum,otab{ifield,1},otab, ...
                    lon_c, lon_u,              ...
                    lat_c, lat_v,              ...
                    z_c, z_w,                  ...
                    sub_name,                  ...
                    lonmin,lonmax,latmin,latmax,depmin,depmax);
 else 
   disp(strcat('##### Skip file (already done):',dirout,sla,...
	       sprintf('%s.%s.nc',otab{ifield,1},sub_name)))
 end %if %file exist
 
 end %if 1/0 want to record ?
% if il==1,break,end;
 
  fclose('all');
  
 end %for il
 
 end %if it
 
end %for i
                                                                                                                                                                                                        gmaze_pv/eg_write_UVbin2cdf_csgrid_subdomain.m                                                      0000644 0023526 0000144 00000021002 10557737072 021146  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % Script to extract a subdomain from a CS510 simulation
% and write in netCDF format on a regular lat/lon grid (1/4)
% SPECIAL U V FIELDS !!
%
clear
global sla
pv_checkpath


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Global setup:
% Restrict global domain to:
subdomain = 3; % North Atlantic

% Path to find input binary Cube sphere files:
pathi = './bin_cube49';

% Path where the netcdf outputs will be stored:
patho = './ecco2_cube49_netcdf';
patho = strcat(patho,sla,'monthly');
%patho = strcat(patho,sla,'six_hourly');

% Time step (for date conversion):
dt = 1200;

% Variables to analyse (index into otab):
otab = cs510grid_outputs_table; % from the 1/8 latlon definition
wvar = [];
dimen = 3;
switch dimen
  case 3 % 3D fields:
    wvar = [wvar 39]; % UVEL
    wvar = [wvar 47]; % VVEL
  case 2 % 2D fields:
end %switch number of dimensions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pre-process
% Get the grid:
path_grid = './grid';
XC = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'XC')),1,'float32');
YC = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'YC')),1,'float32');
XG = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'XG')),1,'float32');
YG = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'YG')),1,'float32');
dxG = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'DXG')),1,'float32');
dyG = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'DYG')),1,'float32');
RAC = readrec_cs510(sprintf('%s.data',strcat(path_grid,sla,'RAC')),1,'float32');
GRID_125;
ZC = - [0 cumsum(thk125(1:length(thk125)-1))];
clear dpt125 lat125 lon125 thk125

% How to move to a lat/lon grid:
% CS510 is about 22km average resolution, ie: 1/4 degree
XI =   -180 : 1/4 : 180; 
YI = -90 : 1/4 : 90;
ZI = ZC;
if ~exist('CS510_to_LATLON025.mat','file')
   del = cube2latlon_preprocess(XC,YC,XI,YI);
   save('CS510_to_LATLON025.mat','XI','YI','XC','YC','del','-v6');
else
   load('CS510_to_LATLON025.mat')
end

% Set subrange - Longitude given as degrees east 
% (exact values come from the 1/8 lat-lon grid)
switch subdomain
  case 3
   sub_name = 'north_atlantic';
   lonmin = 276.0625;
   lonmax = 359.9375;
   latmin = 12.0975;
   latmax = 53.2011;
   depmin = 1;    % !!! indices
   depmax = 29;   % !!! indices
   if dimen == 3, depmax = 29;
   else, depmax = 1;end
   LIMITS = [lonmin lonmax latmin latmax depmin depmax]
   if 0
     m_proj('mercator','long',[270 365],'lat',[0 60]);
     clf;hold on;m_coast;m_grid;
     m_line(LIMITS([1 2 2 1 1]),LIMITS([3 3 4 4 3]),'color','k','linewidth',2);
     title(sub_name);
   end %if 1/0
end

% Get subdomain horizontal axis:
xi = XI(max(find(XI<=LIMITS(1))):max(find(XI<=LIMITS(2))));
yi = YI(max(find(YI<=LIMITS(3))):max(find(YI<=LIMITS(4))));
zi = ZI(LIMITS(5):LIMITS(6));

 filU = otab{39,1}; ifield = 39;
 filV = otab{47,1};
 
%                                                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get info over the time loop
 % Get the file list:
 fildU = filU; % Insert condition here for special files:
 lU = dir(strcat(pathi,sla,fildU));
 fildV = filV; % Insert condition here for special files:
 lV = dir(strcat(pathi,sla,fildV));
 
 % Get the U files list:
 it = 0;
 clear ll
 for il = 1 : size(lU,1)
   if ~lU(il).isdir & ...
	 findstr(lU(il).name,strcat(filU,'.')) % is'it the file type we want ?
     it = it + 1;
     ll(it).name = lU(il).name;
   end %if
 end %for il
 % Create the timetable of U:
 for il = 1 : size(ll,2)
   filin = ll(il).name;
   % Now extract the stepnum from : %s.%10.10d.data
   ic = findstr(filin,filU)+length(filU)+1; i = 1; clear stepnum
   while filin(ic) ~= '.'
      stepnum(i) = filin(ic); i = i + 1; ic = ic + 1;
   end
   ID = str2num(stepnum);
   TIME(il,:) = datestr(datenum(1992,1,1)+ID*dt/60/60/24,'yyyymmddHHMM');
 end
 nt = size(TIME,1);
 
 % Then we check if we have V when we have U:
 for it = 1 : nt
   snapshot = TIME(it,:);
   filUs = ll(it).name;
   filVs = strcat(filV,filUs(findstr(filUs,filU)+length(filU):end));
   if ~exist(strcat(pathi,sla,fildV,sla,filVs),'file')
     TIME(it,:) = NaN;
   end
 end
 itt = 0;
 for it = 1 : nt
   if find(isnan(TIME(it,:))==0)
     itt = itt + 1;
     TI(itt,:) = TIME(it,:);
   end
 end
 TIME = TI; clear TI
 nt = size(TIME,1);
 
 
%                                                 %%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Loop over time
 for it = 1 : nt
   snapshot = TIME(it,:);
   ID = 60*60*24/dt*( datenum(snapshot,'yyyymmddHHMM') - datenum(1992,1,1) );
   filin = ll(it).name;
   disp('')
   disp(strcat('Processing: ',num2str(ID),'//',snapshot))
   dirout = strcat(patho,sla,TIME(it,:),sla);
   filUout = sprintf('%s.%s.nc',filU,sub_name);
   filVout = sprintf('%s.%s.nc',filV,sub_name);
   
   if ~exist(strcat(dirout,sla,filUout),'file') % File already exists ?
   
%%%% READ FILES U AND V
   switch otab{ifield,6}
    case 4, flt = 'float32';
    case 8, flt = 'float64';
   end
   t0 = clock;
   for iC = 1 : 2 
   if iC == 1, fild = fildU; end
   if iC == 2, fild = fildV; filin = strcat(filV,filin(findstr(filin,filU)+length(filU):end)); end
   if findstr(filin,'.gz') % Gunzip file, special care !     
      disp('|----> Find a file with gz extension, work on uncompressed file ...')
      
      % 1: copy the filename with it path into gunzip_1_file.txt
      fid1 = fopen('gunzip_1_file.txt','w');
      fprintf(fid1,'%s',strcat(pathi,sla,fild,sla,filin));fclose(fid1);

      % 2: uncompress the file into a temporary folder:
      disp('|------> uncompressing the file ...')
      ! ./gunzip_1_file.bat
      disp(strcat('|--------: ',num2str(etime(t0,clock))))
      
      % 3: Read the uncompress file:
      disp('|--> reading it ...')
      C = readrec_cs510(strcat('gunzip_1_file',sla,'tempo.data'),LIMITS(6),flt);
      disp(strcat('|----: ',num2str(etime(t0,clock))))
      
      % 4: Suppress it
      ! \rm ./gunzip_1_file/tempo.data
      
   else % Simply read the file:
      disp('|--> reading it ...')
      C = readrec_cs510(strcat(pathi,sla,fild,sla,filin),LIMITS(6),flt);
      disp(strcat('|----: ',num2str(etime(t0,clock))))
   end
   if iC == 1, CU = C; end
   if iC == 2, CV = C; end
   end %for iC
   clear C   
   
%%%% RESTRICT TO SUBDOMAIN
   disp('|--> get subdomain ...')
   % Restrict vertical to subdomain:
   if LIMITS(5) ~= 1
      disp('|----> vertical ...');
      CU = CU(:,:,LIMITS(5):end);
      CV = CV(:,:,LIMITS(5):end);
   end
   % Clean the field:
   CU(find(CU==0)) = NaN; 
   CV(find(CV==0)) = NaN; 
   % Move the field into lat/lon grid:
   disp('|----> Move to lat/lon grid ...');
   [CU CV] = uvcube2latlon_fast3(del,CU,CV,XG,YG,RAC,dxG,dyG);
   
   % And then restrict horizontal to subdomain: 
   disp('|----> horizontal ...');  
   CU = CU(max(find(XI<=LIMITS(1))):max(find(XI<=LIMITS(2))),...
	 max(find(YI<=LIMITS(3))):max(find(YI<=LIMITS(4))),:);
   CV = CV(max(find(XI<=LIMITS(1))):max(find(XI<=LIMITS(2))),...
	 max(find(YI<=LIMITS(3))):max(find(YI<=LIMITS(4))),:);
   
   
%%%% RECORD
   disp('|--> record netcdf file ...')
   
   if 1 % Realy want to record ?
     
   if ~exist(dirout,'dir')
       mkdir(dirout);
   end
   
   for iC = 1 : 2
     if iC==1, ifield=39; C = CU; fil = filU; filout = filUout; end
     if iC==2, ifield=47; C = CV; fil = filV; filout = filVout; end
     fid1 = fopen('inprogress.txt','w');
     fprintf(fid1,'%s',strcat(dirout,sla,filout));fclose(fid1);
   
     nc = netcdf('inprogress.nc','clobber');

     nc('X') = length(xi);
     nc('Y') = length(yi);
     nc('Z') = length(zi);

     nc{'X'}='X';
     nc{'Y'}='Y';
     nc{'Z'}='Z';

     nc{'X'}.uniquename='X';
     nc{'X'}.long_name='longitude';
     nc{'X'}.gridtype=ncint(0);
     nc{'X'}.units='degrees_east';
     nc{'X'}(:) = xi;

     nc{'Y'}.uniquename='Y';
     nc{'Y'}.long_name='latitude';
     nc{'Y'}.gridtype=ncint(0);
     nc{'Y'}.units='degrees_north';
     nc{'Y'}(:) = yi;

     nc{'Z'}.uniquename='Z';
     nc{'Z'}.long_name='depth';
     nc{'Z'}.gridtype=ncint(0);
     nc{'Z'}.units='m';
     nc{'Z'}(:) = zi;

     ncid = fil;
     nc{ncid}={'Z' 'Y' 'X'};
     nc{ncid}.missing_value = ncdouble(NaN);
     nc{ncid}.FillValue_ = ncdouble(0.0);
     nc{ncid}(:,:,:) = permute(C,[3 2 1]);
     nc{ncid}.units = otab{ifield,5};

     close(nc);
     ! ./inprogress.bat
     
   end %if 1/0 want to record ?
   disp(strcat('|--: ',num2str(etime(t0,clock))))
   
   else
     disp(strcat('|--> Skip file (already done):',dirout,sla,filout))
   end %if %file exist
 
   
 end %for iC
 
 end %for it
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END Loop over time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              gmaze_pv/pv_checkpath.m                                                                             0000644 0023526 0000144 00000001430 10650154657 014541  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [] = pv_checkpath()
%
% This function detects where the package gmaze_pv is installed
% (the upper level directory where the function volbet2iso
% is found) and ensure that sub-directories are in the path
%

function [] = pv_checkpath()

% Windows/Linux compatibility
global sla 
sla = '/';
if ispc , sla = '\'; end


% Determine the directory name where the package is installed:
fct_to_find = 'pv_checkpath';
w       = which(fct_to_find);
packdir = w(1:length(w)-(length(fct_to_find)+2));


% Try to found needed subdirectories:

subdir     = struct('name',{'subfct','test','visu','subduc'});

for id = 1 : size(subdir(:),1)
  subdirname = subdir(id).name;
  fullsubdir = strcat(packdir,sla,subdirname);
  if isempty(findstr(path,fullsubdir))
    addpath(fullsubdir)
  end %if
end %for
                                                                                                                                                                                                                                        gmaze_pv/outofdate/intbet2outcrops.m                                                                0000644 0023526 0000144 00000005366 10444547756 017265  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% I  = intbet2outcrops(TRACER,LIMITS,LAT,LONG)
%
% This function computes the horizontal surface integral between two 
% outcrops of the TRACER field, given fixed limits eastward, westward 
% and southward.
%
% TRACER = TRACER(LAT,LONG) : surface tracer variable in 2D
% LIMITS = [OUTCROP1 OUTCROP2 MAX_LAT1 MAX_LAT2 MAX_LONG1 MAX_LONG2]
%          : limit's values (MAX_LAT2 is used only if
%            the outcrop's surfaces reach them).
% LAT                             : latitude axis (1D), degrees northward
% LONG                            : longitude axis (1D), degrees east
% I                               : single surface integral value
%
% 06/15/2006
% gmaze@mit.edu
% 


function varargout = intbet2outcrops(TRACER,LIMITS,LAT,LONG)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRE-PROCESS and ERROR CHECK %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pv_checkpath

% Check number of input:
if nargin ~= 4
  help intbet2outcrops.m
  error('intbet2outcrops.m : Wrong number of parameters')
  return
end %if
  
% Check dimensions:
n = size(TRACER);
if length(n)==2
  [ny nx] = size(TRACER);
  if ny~=length(LAT) | nx~=length(LONG)
     help intbet2outcrops.m
     error('intbet2outcrops.m : Axis must have same dimensions than TRACER field');
     return
  end %if
else
  help intbet2outcrops.m
  error('intbet2outcrops.m : TRACER must be a 2D field')
  return
end %if

% Ensure that axis are of dim: (1,N) and well sorted (increasing values):
a=size(LAT);
if a(1) ~= 1,  LAT=LAT'; end 
S = sort(LAT);
if S ~= LAT
  help intbet2outcrops.m
  error('intbet2outcrops.m : LAT must be increasing values')
  return
end %if
a=size(LONG);
if a(1) ~= 1,  LONG=LONG'; end 
S = sort(LONG);
if S ~= LONG
  help intbet2outcrops.m
  error('intbet2outcrops.m : LONG must be increasing values')
  return
end %if

% LIMITS definition:
if length(LIMITS) ~= 6
  help intbet2outcrops.m
  error('intbet2outcrops.m : LIMITS must contains 6 values')
  return
end %if
OUTCROPS = sort( LIMITS(1:2) );
LAT_MAX  = sort( LIMITS(3:4) );
LONG_MAX = sort( LIMITS(5:6) ); 


  
%%%%%%%%%%%%%%%%%%%%
% COMPUTE INTEGRAL %
%%%%%%%%%%%%%%%%%%%%
% We first determine the element surface matrix and points to integrate:
[I1 I1mat dI1] = subfct_getsurf(TRACER,LAT,LONG,[OUTCROPS(1) LAT_MAX LONG_MAX]);
[I2 I2mat dI2] = subfct_getsurf(TRACER,LAT,LONG,[OUTCROPS(2) LAT_MAX LONG_MAX]);

% Then we determine the outcrop surface limits:
I1mat = abs(I1mat - 1);
Imat  = (I1mat + I2mat)./2;
Imat(find(Imat<1)) = 0;
Imat = logical(Imat);

% And the integral of the TRACER on it:
I = sum(TRACER(Imat).*dI1(Imat));




%%%%%%%%%%%
% OUTPUTS %
%%%%%%%%%%%
switch nargout
 case {0,1}
  varargout(1) = {I};
 case 2
  varargout(1) = {I};
  varargout(2) = {Imat};
 case 3
  varargout(1) = {I};
  varargout(2) = {Imat};
  varargout(3) = {dI1};
end %switch nargout



                                                                                                                                                                                                                                                                          gmaze_pv/outofdate/surfbet2outcrops.m                                                               0000644 0023526 0000144 00000005330 10444550056 017424  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% S  = surfbet2outcrops(TRACER,LIMITS,LAT,LONG)
%
% This function computes the horizontal surface between two outcrops,
% given fixed limits eastward, westward and southward.
%
% TRACER = TRACER(LAT,LONG) : surface tracer variable in 2D
% LIMITS = [OUTCROP1 OUTCROP2 MAX_LAT1 MAX_LAT2 MAX_LONG1 MAX_LONG2]
%          : limit's values (MAX_LAT2 is used only if
%            the outcrop's surfaces reach them).
% LAT                             : latitude axis (1D), degrees northward
% LONG                            : longitude axis (1D), degrees east
% S                               : single surface value (m^2)
%
% 06/14/2006
% gmaze@mit.edu
% 


function varargout = surfbet2outcrops(TRACER,LIMITS,LAT,LONG)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRE-PROCESS and ERROR CHECK %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pv_checkpath

% Check number of input:
if nargin ~= 4
  help surfbet2outcrops.m
  error('surfbet2outcrops.m : Wrong number of parameters')
  return
end %if
  
% Check dimensions:
n = size(TRACER);
if length(n)==2
  [ny nx] = size(TRACER);
  if ny~=length(LAT) | nx~=length(LONG)
     help surfbet2outcrops.m
     error('surfbet2outcrops.m : Axis must have same dimensions than TRACER field');
     return
  end %if
else
  help surfbet2outcrops.m
  error('surfbet2outcrops.m : TRACER must be a 2D field')
  return
end %if

% Ensure that axis are of dim: (1,N) and well sorted (increasing values):
a=size(LAT);
if a(1) ~= 1,  LAT=LAT'; end 
S = sort(LAT);
if S ~= LAT
  help surfbet2outcrops.m
  error('surfbet2outcrops.m : LAT must be increasing values')
  return
end %if
a=size(LONG);
if a(1) ~= 1,  LONG=LONG'; end 
S = sort(LONG);
if S ~= LONG
  help surfbet2outcrops.m
  error('surfbet2outcrops.m : LONG must be increasing values')
  return
end %if

% LIMITS definition:
if length(LIMITS) ~= 6
  help surfbet2outcrops.m
  error('surfbet2outcrops.m : LIMITS must contains 6 values')
  return
end %if
OUTCROPS = sort( LIMITS(1:2) );
LAT_MAX  = sort( LIMITS(3:4) );
LONG_MAX = sort( LIMITS(5:6) ); 


  
%%%%%%%%%%%%%%%%%%%
% COMPUTE SURFACE %
%%%%%%%%%%%%%%%%%%%
% It's computed as the difference between the northern outcrop surface
% and the southern outcrop one.
[S1 S1mat dS1] = subfct_getsurf(TRACER,LAT,LONG,[OUTCROPS(1) LAT_MAX LONG_MAX]);
[S2 S2mat dS2] = subfct_getsurf(TRACER,LAT,LONG,[OUTCROPS(2) LAT_MAX LONG_MAX]);


% Then:
S = max(S1,S2)-min(S1,S2);


% Last we determine the outcrop surface limits:
S1mat = abs(S1mat - 1);
Smat  = (S1mat + S2mat)./2;
Smat(find(Smat<1)) = 0;
Smat = logical(Smat);




%%%%%%%%%%%
% OUTPUTS %
%%%%%%%%%%%
switch nargout
 case {0 , 1}
  varargout(1) = {S};
 case 2
  varargout(1) = {S};
  varargout(2) = {Smat};
 case 3
  varargout(1) = {S};
  varargout(2) = {Smat};
  varargout(3) = {dS1};
end %switch nargout



                                                                                                                                                                                                                                                                                                        gmaze_pv/outofdate/volbet2iso.m                                                                     0000644 0023526 0000144 00000005755 10560500653 016171  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [V,V3D,dV] = volbet2iso(TRACER,LIMITS,DEPTH,LAT,LONG)
%
% This function computes the ocean volume between two iso surfaces,
% given fixed limits eastward, westward and southward.
%
% TRACER = TRACER(DEPTH,LAT,LONG) : surface tracer variable in 3D
% LIMITS = [OUTCROP1 OUTCROP2 MAX_DEPTH MAX_LAT1 MAX_LAT2 MAX_LONG1 MAX_LONG2]
%          : limit's values (MAX_DEPTH and MAX_LAT2 are used only if
%            the iso-outcrop's surfaces reach them).
% DEPTH                           : vertical axis (1D), m downward, positive
% LAT                             : latitude axis (1D), degrees northward
% LONG                            : longitude axis (1D), degrees east
% V                               : single volume value (m^3)
%
% 06/12/2006
% gmaze@mit.edu
% 


function varargout = volbet2iso(TRACER,LIMITS,DEPTH,LAT,LONG)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRE-PROCESS and ERROR CHECK %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pv_checkpath

% Check number of input:
if nargin ~= 5 
  help volbet2iso.m
  error('volbet2iso.m : Wrong number of parameters')
  return
end %if
  
% Check dimensions:
n = size(TRACER);
if length(n)==3
  [nz ny nx] = size(TRACER);
  if nz~=length(DEPTH) | ny~=length(LAT) | nx~=length(LONG)
     help volbet2iso.m
     error('volbet2iso.m : Axis must have same dimensions than TRACER field');
     return
  end %if
else
  help volbet2iso.m
  error('volbet2iso.m : TRACER must be a 3D field')
  return
end %if

% Ensure that axis are of dim: (1,N) and well sorted (increasing values):
a=size(DEPTH);
if a(1) ~= 1,  DEPTH=DEPTH'; end 
S = sort(DEPTH);
if S ~= DEPTH
  help volbet2iso.m
  error('volbet2iso.m : DEPTH must be increasing values')
  return
end %if
a=size(LAT);
if a(1) ~= 1,  LAT=LAT'; end 
S = sort(LAT);
if S ~= LAT
  help volbet2iso.m
  error('volbet2iso.m : LAT must be increasing values')
  returny
end %if
a=size(LONG);
if a(1) ~= 1,  LONG=LONG'; end 
S = sort(LONG);
if S ~= LONG
  help volbet2iso.m
  error('volbet2iso.m : LONG must be increasing values')
  return
end %if

% LIMITS definition:
if length(LIMITS) ~=7
  help volbet2iso.m
  error('volbet2iso.m : LIMITS must contains 7 values')
  return
end %if
OUTCROPS = sort( LIMITS(1:2) );
H_MAX    = LIMITS(3);
LAT_MAX  = sort( LIMITS(4:5) );
LONG_MAX = sort( LIMITS(6:7) ); 

  
%%%%%%%%%%%%%%%%%%
% COMPUTE VOLUME %
%%%%%%%%%%%%%%%%%%
% It's computed as the difference between the northern outcrop volume
% and the southern outcrop one.
[V1 V1mat dV1] = subfct_getvol(TRACER,DEPTH,LAT,LONG,[OUTCROPS(1) H_MAX LAT_MAX LONG_MAX]);
[V2 V2mat dV2] = subfct_getvol(TRACER,DEPTH,LAT,LONG,[OUTCROPS(2) H_MAX LAT_MAX LONG_MAX]);


% Then:
V = max(V1,V2)-min(V1,V2);


% Last we determine the iso-0 volume limits:
V1mat = abs(V1mat - 1);
Vmat  = (V1mat + V2mat)./2;
Vmat(find(Vmat<1)) = 0;
Vmat = logical(Vmat);



%%%%%%%%%%%
% OUTPUTS %
%%%%%%%%%%%
switch nargout
 case {0,1}
  varargout(1) = {V};
 case 2
  varargout(1) = {V};
  varargout(2) = {Vmat};
 case 3
  varargout(1) = {V};
  varargout(2) = {Vmat};
  varargout(3) = {dV1};
end %switch nargout



                   gmaze_pv/subduc/Contents.m                                                                          0000644 0023526 0000144 00000001462 10636770564 015176  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % $$$ This directory contains scripts written by Jake Gebbie for diagnosing
% $$$ subduction rates. All scripts are for offline diagnostics in MATLAB.
% $$$ 
% $$$ 
% $$$ Eulerian maps of subduction:
% $$$   diag_sann.m: Diagnose the annual subduction rate.
% $$$   diag_induction.m: Diagnose lateral induction across a surface (usually the
% $$$    mixed-layer base)
% $$$   get_mldvel.m: Interpolate the velocity field to a surface (usually the
% $$$     mixed-layer base)
% $$$   
% $$$ Water-mass diagnostics:
% $$$   To be included at a future date.
% $$$ 
% $$$ Utilities:
% $$$   mldepth.m: Calculate mixed-layer depth from the density field.
% $$$   cshift.m: A MATLAB replica of the popular Fortran function.
% $$$   integrate_for_w.m: A MATLAB rendition of the MITgcm subroutine 
% $$$     of the same name.
                                                                                                                                                                                                              gmaze_pv/subduc/cshift.m                                                                            0000644 0023526 0000144 00000001032 10636770656 014654  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function [out] = cshift(in,DIM,shift)
%function [out] = cshift(in,DIM,shift)
%
% Replicate the CSHIFT function in F90 (?). 
%
% G. Gebbie, MIT-WHOI, Dec 2003.

 totaldims = ndims(in);
 index = 1: totaldims;
 index(index==DIM) = [];
 index = [DIM index];
 sizin = size(in);
 in = permute(in,index);
 in = reshape(in,sizin(DIM),prod(sizin)./sizin(DIM));

 if shift>=0
   shift = shift - size(in,1);
 end  

 out = [in(shift+1+size(in,1):size(in,1),:);in(1:size(in,1)+shift,:)];
 out = reshape(out,sizin(index));
 out = ipermute(out,index);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      gmaze_pv/subduc/diag_induction.m                                                                    0000644 0023526 0000144 00000001257 10636770732 016360  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function [induction,gradx,grady] = diag_induction(ustar,vstar,h,dxc,dyc);
%function [induction,gradx,grady] = diag_induction(ustar,vstar,h,dxc,dyc)
%
% Diagnose lateral induction u_h . grad h 
%
% G. Gebbie, 2003. 

 [nx,ny] = size(ustar);

 gradx(2:nx,:) = (h(2:nx,:)  - h(1:nx-1,:));
 grady(:,2:ny) =  h(:,2:ny)  - h(:,1:ny-1);

 gradx = gradx ./ dxc;
 grady = grady ./ dyc;

 udelh = ustar .* gradx;
 vdelh = vstar .* grady;

%% now move udelh from U points to H points, in order to match up with W*.
%% involves an average.
 udelh2 = (udelh(2:nx,:)+udelh(1:nx-1,:))./2;
 vdelh2 = (vdelh(:,2:ny)+vdelh(:,1:ny-1))./2;

 udelh2(nx,:) = 0;
 vdelh2(:,ny)=0;

induction = udelh2 + vdelh2;
                                                                                                                                                                                                                                                                                                                                                 gmaze_pv/subduc/diag_sann.m                                                                         0000644 0023526 0000144 00000002164 10637030046 015305  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function [sann,stot,latind,wmstar] = diag_sann(umean,vmean,wmean,maxmld,Z,delZ,dxc,dyc,raw,mask);
%function [sann,stot,latind,wmstar] = diag_sann(umean,vmean,wmean,maxmld,Z,delZ,dxc,dyc,raw,mask)
%
% Diagnose annual subduction rate of Marshall et al 1993.
% S_ann = -w_H - u_H . del H, [m/yr]
%
% Also, diagnose S_tot, total subduction estimated from
%  annual subduction rate.
% S_tot = \int S_ann dt dA, [Sv]
%
% intermediate terms of calculation:
% latind = u_H . del H = lateral induction
% wmstar = w_H = vertical velocity at h = maxmld.
%
% mask = 2D mask for calculation of subrate.
%
% Z     < 0
% delZ  < 0
% h     < 0 
%
% Started: D. Jamous 1996, Fortran diagnostics.
% Updated: G. Gebbie, 2003, MIT-WHOI for Matlab.

 %% map the mean velocity onto the maxmld surface.
 [umstar,vmstar,wmstar] = get_mldvel(umean,vmean,wmean,Z,delZ,maxmld);

 %% compute mean lateral induction.
 [latind] = diag_induction(umstar,vmstar,maxmld,dxc,dyc);

 sann = -wmstar - latind;

 sann = sann .*86400 .*365; %convert to meters/year.
 
 sanntmp = sann;
 sanntmp(isnan(sanntmp))=0;
 stot=nansum(nansum(sanntmp.*raw.*mask))./(86400)./365 
 
 return
                                                                                                                                                                                                                                                                                                                                                                                                            gmaze_pv/subduc/get_mldvel.m                                                                        0000644 0023526 0000144 00000001661 10637042472 015513  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function [ustar,vstar,wstar] = get_mldvel(u,v,w,depth,delZ,h)
%function [ustar,vstar,wstar] = get_mldvel(u,v,w,Z,delZ,h)
%
% Get velocity at a surface h = h(x,y).
% Velocity remains on the C-grid with depths "depth".
%
% depth < 0
% delZ  < 0
% h     < 0 
%
% G. Maze: remove extra function dependance
% 
% Started: D. Jamous, 1996, FORTRAN diags.
%
% Translated: G. Gebbie, MIT-WHOI, November 2003.

[nx,ny,nz]=size(u);

 ustar = zeros(nx,ny);
 vstar = zeros(nx,ny);
 wstar = zeros(nx,ny);

 zbot = cumsum(delZ)';
 zbot = depth;

 for i=2:nx-1
   for j=2:ny-1
     ustar(i,j) = interp1( depth, squeeze(u(i,j,:)),(h(i,j)+h(i-1,j))./2,'linear');
     vstar(i,j) = interp1( depth, squeeze(v(i,j,:)),(h(i,j)+h(i,j-1))./2,'linear');
   end
 end
 for i=1:nx-1
   for j=1:ny-1
     wstar(i,j) = interp1( squeeze(zbot(1:nz)), squeeze(w(i,j,:)), h(i,j), 'linear');
   end
 end

 ustar(isnan(ustar))= 0;
 vstar(isnan(vstar))= 0;
 wstar(isnan(wstar))= 0;
                                                                               gmaze_pv/subduc/integrate_for_w.m                                                                   0000644 0023526 0000144 00000001725 10636771041 016550  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function [w] = integrate_for_w(u,v,dxg,dyg,raw, delZ )
%function [w] = integrate_for_w(u,v,dxg,dyg, raw, delZ )
%
% Get the vertical velocity from the horizontal velocity.
% Use the conservation of volume for this computation. 
% U and V are 3-dimensional.
% Following the MITgcm subroutine, integrate_for_w.F
%
% uncertain about the halo region.
%
% G. Gebbie, MIT-WHOI, 2003.
%

[nx ny nz] = size(u);

k=1:nz;
utrans(:,:,k) = u(:,:,k) .* dyg(:,:,ones(1,nz));
vtrans(:,:,k) = v(:,:,k) .* dxg(:,:,ones(1,nz));

%% is this the best way to overlap?
utrans(nx+1,:,k) = utrans(1,:,k);
vtrans(:,ny+1,k) = vtrans(:,1,k);

%w(:,:,23) = zeros(nx,ny,nz);

kbot = nz;
i=1:nx;
j=1:ny;
w(:,:,kbot) = - (utrans(i+1,j,kbot) - utrans(i,j,kbot) + ...
                 vtrans(i,j+1,kbot) - vtrans(i,j,kbot)) ...
		 .*(delZ(kbot)) ./raw(i,j);

for k=nz-1:-1:1
  w(:,:,k) = w(:,:,k+1)- ((utrans(i+1,j,k) - utrans(i,j,k) + ...
	  vtrans(i,j+1,k) - vtrans(i,j,k)) .* (delZ(k) ./raw(i,j)));
end

return
                                           gmaze_pv/subduc/mlddepth.m                                                                          0000644 0023526 0000144 00000004564 10636771064 015204  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function [mld,rho] = mldepth(T,S,depth,epsilon)
%function [mld,rho] = mldepth(T,S,depth,epsilon)
%
% Solve for mixed layer depth on a 1-meter resolution grid.
% 
% Handles input temperature and salinity of any dimension, i.e. 2-D, 3-D,
% 4-D, with time and space in any order.
% 
% Returns mixed layer depth in same dimension as T,S, except without 
% the vertical dimension.
%
% depth = depths on which theta and S are defined.
% epsilon = threshold for density difference, surface to mixld.
%
% Method: Solve for potential density with the surface reference pressure.
%         Interpolate density onto a 1-meter resolution grid.
%         Search for the depth where surface density differs by some
%         threshold. This depth is the mixed layer depth.
%
% G. Gebbie, MIT-WHOI, August 22, 2001. on board the R/V Oceanus.
%
% Vectorized for Matlab, November 2003. GG. MIT-WHOI.
%
% required: seawater toolbox. WARNING: SEAWATER TOOLBOX SYNTAX
%  MAY HAVE CHANGED.

 mldlimit = 500 ;%  a priori maximum limit of mixed layer depth

 S( S == 0) = NaN;
 T( T == 0) = NaN;

% mldlimit is the limit of mixed layer depth here.
 grrid = (2*depth(1)):1:mldlimit;
 
% Set reference pressure to zero. Should not make a difference if mixld < 500.
 pr =0;

%%  The vertical direction is special. Its dimension is specified by "depth". 
 nz = length(depth);

 nn = size(T);

%% Find vertical dimension.
 zindex = find(nn==nz);

 oindex = 1:ndims(T);
 oindex(oindex==zindex)=[];
 nx = prod(nn(oindex));

%% Put the vertical direction at the end. Squeeze the rest.
 temp = permute(T,[oindex zindex]);
 temp = reshape(temp,nx,nz);
% temp (temp==0) = nan;

 salt = permute(S,[1 2 4 3]);
 salt = reshape(salt,nx,nz);
% salt (salt==0) = nan;
  
 pden = sw_pden(salt,temp,depth,pr);

 if nargout ==2
   rho = reshape(pden,[nn(oindex) nz]) ;  
   rho = permute(rho,[1 2 4 3]);
 end
  
 temphi = interp1( depth', pden', grrid);
 differ = cumsum(diff(temphi));

 %% preallocate memory.
 mld = zeros(nx,1);
 
 % how would one vectorize this section?
 for i = 1:nx
    index =find(differ(:,i)> epsilon);
   if( isempty ( index) ==1)
     tmpmld  = NaN;
   else
     tmpmld = grrid( index(1));
   end 
   mld(i) = tmpmld;
 end

 % Make the user happy. Return mixed layer depth in the same form as the
 % input T,S, except vertical dimension is gone.
 
 mld = reshape(mld,[nn(oindex) 1]);
 mld = squeeze(mld);

 mld(isnan(mld)) = 0;
 
 return
                                                                                                                                            gmaze_pv/subfct/boxcar.m                                                                            0000644 0023526 0000144 00000004476 10650145007 014650  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % PII = boxcar(C3D,H,X,Y,Z,isoC,dC)
% The boxcar function:
%                               {  isoC-dC/2 <= C3D(iZ,iY,iX) < isoC + dC/2
% PII(isoC,C3D(iZ,iY,iX) = 1 if:{  Z(iZ) > H(iY,iX)
%                        = 0 otherwise
%
% Rq:
% H may be a single value
% Z and H should be negative
% Z orientatd downward
%

%function [PII] = boxcar(C3D,H,X,Y,Z,isoC,dC)

function [PII A B C] = boxcar(C3D,H,X,Y,Z,isoC,dC)

nz  = length(Z);
ny  = length(Y);
nx  = length(X);

method = 2;

if length(H) == 1, H = H.*ones(ny,nx); end

switch method
  case 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     PII = zeros(nz,ny,nx); 
     warning off
     for ix = 1 : nx
       for iy = 1 : ny
	 Cprof = squeeze(C3D(:,iy,ix));
	 li = find( isoC-dC/2 <= Cprof   & ...
		        Cprof < isoC+dC/2 & ...
		            Z > H(iy,ix) );
	 if ~isempty(li)
	   PII(li,iy,ix) = 1;
	 end %if
       end %for iy
     end %for ix
     warning on

  case 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     PII = ones(nz,ny,nx); 
     
     [a b]=meshgrid(Z,H); b=reshape(b,[ny nx nz]);b=permute(b,[3 1 2]);H=b;clear a b
     [a b c]=meshgrid(Z,Y,X);a=permute(a,[2 1 3]);Z=a;clear a b c
     
     PII(find( -dC/2 < C3D-isoC & C3D-isoC <= +dC/2 & H<=Z  ))  = 0;
     PII = 1-PII;


end %switch method


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Also provide the 1/0 matrix of the layer boundaries:
bounds_vert = zeros(nz,ny,nx);
bounds_meri = zeros(nz,ny,nx);

for ix = 1 : nx
piisect   = squeeze(PII(:,:,ix));
boundsect = zeros(nz,ny);
% Determine vertical boundaries of the layer:
for iy = 1 : ny
  li = find(piisect(:,iy)==1);
  if length(li) ~= 0
    boundsect(li(1),iy)  = 1;
    boundsect(li(end),iy) = 1;
  end
end
bounds_vert(:,:,ix) = boundsect;

boundsect = zeros(nz,ny);
% Determine horizontal meridional boundaries of the layer:
for iz = 1 : nz
  li = find(piisect(iz,:)==1);
  if length(li) ~= 0
    boundsect(iz,li(1))   = 1;
    boundsect(iz,li(end)) = 1;
  end
end
bounds_meri(:,:,ix) = boundsect;

end %for ix

bounds_zona = zeros(nz,ny,nx);
for iy = 1 : ny
piisect   = squeeze(PII(:,iy,:));
boundsect = zeros(nz,nx);
% Determine horizontal zonal boundaries of the layer:
for iz = 1 : nz
  li = find(piisect(iz,:)==1);
  if length(li) ~= 0
    boundsect(iz,li(1))   = 1;
    boundsect(iz,li(end)) = 1;
  end
end
bounds_zona(:,iy,:) = boundsect;
end %for iy

A = bounds_vert;
B = bounds_meri;
C = bounds_zona;

                                                                                                                                                                                                  gmaze_pv/subfct/coordfromnc.m                                                                       0000644 0023526 0000144 00000000764 10650144750 015705  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % [X,Y,Z] = COORDFROMNC(NC)
%
% Given a netcdf file, return 3D coordinates values 
% in X, Y and Z
%


function varargout = coordfromnc(nc)

co = coord(nc);


switch nargout
 case 1
  varargout(1) = {co{1}(:)};
 case 2
  varargout(1) = {co{1}(:)};
  varargout(2) = {co{2}(:)};
 case 3
  varargout(1) = {co{1}(:)};
  varargout(2) = {co{2}(:)};
  varargout(3) = {co{3}(:)};
 case 4
  varargout(1) = {co{1}(:)};
  varargout(2) = {co{2}(:)};
  varargout(3) = {co{3}(:)};
  varargout(4) = {co{4}(:)};
end
            gmaze_pv/subfct/cs510grid_outputs_table.m                                                           0000644 0023526 0000144 00000011076 10650144733 020044  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function otab = cs510grid_outputs_table

% otab = cs510grid_outputs_table() 
% ONLY FOR CUBE40
% Fields
% 1 - file prefix
% 2 - dimensions
% 3 - grid location
% 4 - id string (defaults to file prefix if unknown)
% 5 - units
% 6 - bytes per value


otab=[{'AREAtave'},   {'xy'}, {'c'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'ETAN'},       {'xy'}, {'c'}, {'ssh'}, {'m'}, {4},
      {'ETANSQ'},     {'xy'}, {'c'}, {'ssh_squared'}, {'m^2'}, {4},
      {'EXFhl'},      {'xy'}, {'c'}, {'latent_heat_flux'}, {'W/m^2'}, {4},
      {'EXFhs'},      {'xy'}, {'c'}, {'sensible_heat_flux'}, {'W/m^2'}, {4},
      {'EXFlw'},      {'xy'}, {'c'}, {'longwave_radiation'}, {'W/m^2'}, {4},
      {'EXFsw'},      {'xy'}, {'c'}, {'shortwave_radiation'}, {'W/m^2'}, {4},
      {'EmPmRtave'},  {'xy'}, {'c'}, {'net_evaporation'}, {'m/s'}, {4},
      {'FUtave'},     {'xy'}, {'c'}, {'averaged_zonal_stress'}, {'N/m^2'}, {4},
      {'FVtave'},     {'xy'}, {'c'}, {'averaged_meridional_stress'}, {'N/m^2'}, {4},
      {'HEFFtave'},   {'xy'}, {'c'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'KPPhbl'},     {'xy'}, {'c'}, {'thermocline_base'}, {'m'}, {4},
      {'KPPmld'},     {'xy'}, {'c'}, {'mixed_layer_depth'}, {'m'}, {4},
      {'PHIBOT'},     {'xy'}, {'c'}, {'bottom_pressure'}, {'Pa'}, {4},
      {'QNETtave'},   {'xy'}, {'c'}, {'averaged_net_heatflux'}, {'W/m^2'}, {4},
      {'QSWtave'},    {'xy'}, {'c'}, {'averaged_shortwave_heatflux'}, {'W/m^2'}, {4},
      {'SFLUX'},      {'xy'}, {'c'}, {'salinity_flux'}, {'psu/s'}, {4},
      {'SRELAX'},     {'xy'}, {'c'}, {'salinity_relaxation'}, {'psu/s'}, {4},
      {'SSS'},        {'xy'}, {'c'}, {'sea_surface_salinity'}, {'psu'}, {4},
      {'SST'},        {'xy'}, {'c'}, {'sea_surface_temperature'}, {'degrees_centigrade'}, {4},
      {'TAUX'},       {'xy'}, {'c'}, {'zonal_wind_stress'}, {'N/m^2'}, {4},
      {'TAUY'},       {'xy'}, {'c'}, {'meridional_wind_stress'}, {'N/m^2'}, {4},
      {'TFLUX'},      {'xy'}, {'c'}, {'temperature_flux'}, {'W/m^2'}, {4},
      {'TICE'},       {'xy'}, {'c'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'UICEtave'},   {'xy'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'UVEL_k2'},    {'xy'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VICEtave'},   {'xy'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VVEL_k2'},    {'xy'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'DRHODR'},    {'xyz'}, {'w'}, {'vertical_density_gradient'}, {'kg/m^4'}, {4},
      {'RHOANOSQ'},  {'xyz'}, {'c'}, {'density_anomaly_squared'}, {'(kg/m^3-1000)^2'}, {4},
      {'RHOAnoma'},  {'xyz'}, {'c'}, {'density_anomaly'}, {'kg/m^3-1000'}, {4},
      {'SALTSQan'},  {'xyz'}, {'c'}, {'salinity_anomaly_squared'}, {'(psu-35)^2'}, {4},
      {'SALTanom'},  {'xyz'}, {'c'}, {'salinity_anomaly'}, {'psu-35'}, {8},
      {'THETA'},     {'xyz'}, {'c'}, {'potential_temperature'}, {'degrees_centigrade'}, {8},
      {'THETASQ'},   {'xyz'}, {'c'}, {'potential_temperature_squared'}, {'degrees_centigrade^2'}, {8},
      {'URHOMASS'},  {'xyz'}, {'u'}, {'zonal_mass_transport'}, {'kg.m^3/s'}, {4},
      {'USLTMASS'},  {'xyz'}, {'u'}, {'zonal_salt_transport'}, {'psu.m^3/s'}, {4},
      {'UTHMASS'},   {'xyz'}, {'u'}, {'zonal_temperature_transport'}, {'degrees_centigrade.m^3/s'}, {4},
      {'UVEL'},      {'xyz'}, {'u'}, {'zonal_flow'}, {'m/s'}, {4},
      {'UVELMASS'},  {'xyz'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'UVELSQ'},    {'xyz'}, {'u'}, {'zonal_flow_squared'}, {'(m/s)^2'}, {4},
      {'UV_VEL_Z'},  {'xyz'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VISCA4'},    {'xyz'}, {'c'}, {'biharmonic_viscosity'}, {'m^4/s'}, {4},
      {'VRHOMASS'},  {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VSLTMASS'},  {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VTHMASS'},   {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VVEL'},      {'xyz'}, {'v'}, {'meridional_velocity'}, {'m/s'}, {4},
      {'VVELMASS'},  {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VVELSQ'},    {'xyz'}, {'v'}, {'meridional_velocity_squared'}, {'(m/s)^2'}, {4},
      {'WRHOMASS'},  {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WSLTMASS'},  {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WTHMASS'},   {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WU_VEL'},    {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WVELMASS'},  {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WVELSQ'},    {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WV_VEL'},    {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4}];

                                                                                                                                                                                                                                                                                                                                                                                                                                                                  gmaze_pv/subfct/densjmd95.m                                                                         0000644 0023526 0000144 00000014677 10650144624 015204  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % DENSJMD95:    Density of sea water
%=========================================================================
%
% USAGE:  dens = densjmd95(S,Theta,P)
%
% DESCRIPTION:
%    Density of Sea Water using Jackett and McDougall 1995 (JAOT 12) 
%    polynomial (modified UNESCO polynomial).
%
% INPUT:  (all must have same dimensions)
%   S     = salinity    [psu      (PSS-78)]
%   Theta = potential temperature [degree C (IPTS-68)]
%   P     = pressure    [dbar]
%       (P may have dims 1x1, mx1, 1xn or mxn for S(mxn) )
%
% OUTPUT:
%   dens = density  [kg/m^3] 
% 
% AUTHOR:  Martin Losch 2002-08-09  (mlosch@mit.edu)
%
% check value
% S     = 35.5 PSU
% Theta = 3 degC
% P     = 3000 dbar
% rho   = 1041.83267 kg/m^3
%

% Jackett and McDougall, 1995, JAOT 12(4), pp. 381-388

% created by mlosch on 2002-08-09

  function rho = densjmd95(s,t,p)
  
  
%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
  if nargin ~=3
    error('densjmd95.m: Must pass 3 parameters')
  end 
  if ndims(s) > 2
    dims = size(s);
    dimt = size(t);
    dimp = size(p);
    if length(dims) ~= length(dimt) | length(dims) ~= length(dimp) ...
	  | length(dimt) ~= length(dimp)
      error(['for more than two dimensions, S, Theta, and P must have the' ...
	     ' same number of dimensions'])
    else
      for k=length(dims)
	if dims(k)~=dimt(k) | dims(k)~=dimp(k) | dimt(k)~=dimp(k)
	  error(['for more than two dimensions, S, Theta, and P must have' ...
		 ' the same dimensions'])
	end
      end
    end
  else
    % CHECK S,T,P dimensions and verify consistent
    [ms,ns] = size(s);
    [mt,nt] = size(t);
    [mp,np] = size(p);
    
    % CHECK THAT S & T HAVE SAME SHAPE
    if (ms~=mt) | (ns~=nt)
      error('check_stp: S & T must have same dimensions')
    end %if
    
    % CHECK OPTIONAL SHAPES FOR P
    if     mp==1  & np==1      % P is a scalar.  Fill to size of S
      p = p(1)*ones(ms,ns);
    elseif np==ns & mp==1      % P is row vector with same cols as S
      p = p( ones(1,ms), : ); %   Copy down each column.
    elseif mp==ms & np==1      % P is column vector
      p = p( :, ones(1,ns) ); %   Copy across each row
    elseif mp==ms & np==ns     % P is a matrix size(S)
			       % shape ok 
    else
      error('check_stp: P has wrong dimensions')
    end %if
    [mp,np] = size(p);
    % IF ALL ROW VECTORS ARE PASSED THEN LET US PRESERVE SHAPE ON RETURN.
    Transpose = 0;
    if mp == 1  % row vector
      p       =  p(:);
      t       =  t(:);
      s       =  s(:);   
      Transpose = 1;
    end 
    %***check_stp
  end
  
  % convert pressure to bar
  p = .1*p;
    
  % coefficients nonlinear equation of state in pressure coordinates for
  % 1. density of fresh water at p = 0
  eosJMDCFw(1) =  999.842594;
  eosJMDCFw(2) =    6.793952e-02;
  eosJMDCFw(3) = -  9.095290e-03;
  eosJMDCFw(4) =    1.001685e-04;
  eosJMDCFw(5) = -  1.120083e-06;
  eosJMDCFw(6) =    6.536332e-09;
  % 2. density of sea water at p = 0
  eosJMDCSw(1) =    8.244930e-01;
  eosJMDCSw(2) = -  4.089900e-03;
  eosJMDCSw(3) =    7.643800e-05 ;
  eosJMDCSw(4) = -  8.246700e-07;
  eosJMDCSw(5) =    5.387500e-09;
  eosJMDCSw(6) = -  5.724660e-03;
  eosJMDCSw(7) =    1.022700e-04;
  eosJMDCSw(8) = -  1.654600e-06;
  eosJMDCSw(9) =    4.831400e-04;

  t2 = t.*t;
  t3 = t2.*t;
  t4 = t3.*t;
  
  is = find(s(:) < 0 );
  if ~isempty(is)
    warning('found negative salinity values, reset them to NaN');
    s(is) = NaN;
  end
  s3o2 = s.*sqrt(s);
            
  % density of freshwater at the surface
  rho =   eosJMDCFw(1) ...
	+ eosJMDCFw(2)*t ...
	+ eosJMDCFw(3)*t2 ...
	+ eosJMDCFw(4)*t3 ...
	+ eosJMDCFw(5)*t4 ...
	+ eosJMDCFw(6)*t4.*t;
  % density of sea water at the surface
  rho =  rho ...
	 + s.*( ...
	     eosJMDCSw(1) ...
	     + eosJMDCSw(2)*t ...
	     + eosJMDCSw(3)*t2 ...
	     + eosJMDCSw(4)*t3 ...
	     + eosJMDCSw(5)*t4 ...
	     ) ...
         + s3o2.*( ...
	     eosJMDCSw(6) ...
	     + eosJMDCSw(7)*t ...
	     + eosJMDCSw(8)*t2 ...
	     ) ...
	 + eosJMDCSw(9)*s.*s;

  rho = rho./(1 - p./bulkmodjmd95(s,t,p));
  
  if ndims(s) < 3 & Transpose
    rho = rho';
  end %if
  
  return
  
function bulkmod = bulkmodjmd95(s,t,p)
%function bulkmod = bulkmodjmd95(s,t,p)
  
  dummy = 0;
  % coefficients in pressure coordinates for
  % 3. secant bulk modulus K of fresh water at p = 0
  eosJMDCKFw(1) =   1.965933e+04;
  eosJMDCKFw(2) =   1.444304e+02;
  eosJMDCKFw(3) = - 1.706103e+00;
  eosJMDCKFw(4) =   9.648704e-03;
  eosJMDCKFw(5) = - 4.190253e-05;
  % 4. secant bulk modulus K of sea water at p = 0
  eosJMDCKSw(1) =   5.284855e+01;
  eosJMDCKSw(2) = - 3.101089e-01;
  eosJMDCKSw(3) =   6.283263e-03;
  eosJMDCKSw(4) = - 5.084188e-05;
  eosJMDCKSw(5) =   3.886640e-01;
  eosJMDCKSw(6) =   9.085835e-03;
  eosJMDCKSw(7) = - 4.619924e-04;
  % 5. secant bulk modulus K of sea water at p
  eosJMDCKP( 1) =   3.186519e+00;
  eosJMDCKP( 2) =   2.212276e-02;
  eosJMDCKP( 3) = - 2.984642e-04;
  eosJMDCKP( 4) =   1.956415e-06;
  eosJMDCKP( 5) =   6.704388e-03;
  eosJMDCKP( 6) = - 1.847318e-04;
  eosJMDCKP( 7) =   2.059331e-07;
  eosJMDCKP( 8) =   1.480266e-04;
  eosJMDCKP( 9) =   2.102898e-04;
  eosJMDCKP(10) = - 1.202016e-05;
  eosJMDCKP(11) =   1.394680e-07;
  eosJMDCKP(12) = - 2.040237e-06;
  eosJMDCKP(13) =   6.128773e-08;
  eosJMDCKP(14) =   6.207323e-10;

  t2 = t.*t;
  t3 = t2.*t;
  t4 = t3.*t;

  is = find(s(:) < 0 );
  if ~isempty(is)
    warning('found negative salinity values, reset them to NaN');
    s(is) = NaN;
  end
  s3o2 = s.*sqrt(s);
  %p = pressure(i,j,k,bi,bj)*SItoBar
  p2 = p.*p;
  % secant bulk modulus of fresh water at the surface
  bulkmod =   eosJMDCKFw(1) ...
	    + eosJMDCKFw(2)*t ...
	    + eosJMDCKFw(3)*t2 ...
	    + eosJMDCKFw(4)*t3 ...
	    + eosJMDCKFw(5)*t4;
  % secant bulk modulus of sea water at the surface
  bulkmod = bulkmod ...
	    + s.*(   eosJMDCKSw(1) ...
		     + eosJMDCKSw(2)*t ...
		     + eosJMDCKSw(3)*t2 ...
		     + eosJMDCKSw(4)*t3 ...
		     ) ...
	    + s3o2.*(   eosJMDCKSw(5) ...
			+ eosJMDCKSw(6)*t ...
			+ eosJMDCKSw(7)*t2 ...
			);
  % secant bulk modulus of sea water at pressure p
  bulkmod = bulkmod ...
	    + p.*(   eosJMDCKP(1) ...
		     + eosJMDCKP(2)*t ...
		     + eosJMDCKP(3)*t2 ...
		     + eosJMDCKP(4)*t3 ...
		     ) ...
	    + p.*s.*(   eosJMDCKP(5) ...
			+ eosJMDCKP(6)*t ...
			+ eosJMDCKP(7)*t2 ...
			) ...
	    + p.*s3o2*eosJMDCKP(8) ...
	    + p2.*(   eosJMDCKP(9) ...
		      + eosJMDCKP(10)*t ...
		      + eosJMDCKP(11)*t2 ...
		      ) ...
	    + p2.*s.*(   eosJMDCKP(12) ...
			 + eosJMDCKP(13)*t ...
			 + eosJMDCKP(14)*t2 ...
			 );

      return

                                                                 gmaze_pv/subfct/diagCatH.m                                                                          0000644 0023526 0000144 00000001147 10641300521 015020  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % Ch = diagCatH(C,depth,h)
%
% Get field C(depth,lat,lon) at depth h(lat,lon)
%
% depth < 0
% h     < 0 
%
% G. Maze, MIT, June 2007
%y

function varargout = diagCatH(C,Z,h)

% 0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREPROC
[nz,ny,nx] = size(C);
Ch = zeros(ny,nx);

% 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPUTING
warning off
 for ix = 1 : nx
   for iy = 1 : ny
     Ch(iy,ix) = interp1( Z, squeeze(C(:,iy,ix)) , h(iy,ix) , 'linear');
   end
 end
warning on
 
% 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUTS
switch nargout
 case 1
  varargout(1) = {Ch};
end                                                                                                                                                                                                                                                                                                                                                                                                                         gmaze_pv/subfct/diagHatisoC.m                                                                       0000644 0023526 0000144 00000004210 10641267270 015542  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % [H,h,[dH,dh]] = diagHatisoC(C,Z,isoC,[dC])
%
% Get depth of C(depth,lat,lon) = isoC
% Z < 0
%
% OUTPUTS:
% H(lat,lon) is the depth determine with the input resolution
% h(lat,lon) is a more accurate depth (determined with interpolation)
% dH(lat,lon) is the thickness of the layer: isoC-dC < C < isoC+dC from H
% dh(lat,lon) is the thickness of the layer: isoC-dC < C < isoC+dC from h
%
% G. Maze, MIT, June 2007
%

function varargout = diagHatisoC(C,Z,isoC,varargin)


% 0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREPROC
[nz,ny,nx] = size(C);
H = zeros(ny,nx).*NaN;
if nargout >= 2
  h = zeros(ny,nx).*NaN;
  z = [0:-1:Z(end)]; % Vertical axis of the interpolated depth
  if nargin == 4
    dh = zeros(ny,nx).*NaN;
  end
end
if nargin == 4
  dC = varargin{1};
  dH = zeros(ny,nx).*NaN;
end

% 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPUTING
warning off
 for ix = 1 : nx
   for iy = 1 : ny
     c = squeeze(C(:,iy,ix))';   
     if isnan(c(1)) ~= 1
     if length(find(c>=isoC))>0 & length(find(c<=isoC))>0
	
        % Raw value:
	[cm icm] = min(abs(abs(c)-abs(isoC)));
        H(iy,ix) = Z(icm);
	
	if nargout >= 2
          % Interp guess:
          cc = feval(@interp1,Z,c,z,'linear');
	  [cm icm] = min(abs(abs(cc)-abs(isoC)));
          h(iy,ix) = z(icm);
	end % if 2 outputs
	
	if nargin == 4
   	   [cm icm1] = min(abs(abs(c)-abs(isoC+dC)));
   	   [cm icm2] = min(abs(abs(c)-abs(isoC-dC)));
           dH(iy,ix) = max(Z([icm1 icm2])) - min(Z([icm1 icm2]));
	   
	   if nargout >= 2
   	      [cm icm1] = min(abs(abs(cc)-abs(isoC+dC)));
   	      [cm icm2] = min(abs(abs(cc)-abs(isoC-dC)));
              dh(iy,ix) = max(z([icm1 icm2])) - min(z([icm1 icm2]));
	   end % if 2 outputs
	end % if thickness
	
     end % if found value in the profile
     end % if point n ocean
   end
 end
warning on 
 
% 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUTS
switch nargout
 case 1
  varargout(1) = {H};
 case 2
  varargout(1) = {H};
  varargout(2) = {h};
 case 3
  varargout(1) = {H};
  varargout(2) = {h};
  varargout(3) = {dH};
 case 4
  varargout(1) = {H};
  varargout(2) = {h};
  varargout(3) = {dH};
  varargout(4) = {dh};
end
                                                                                                                                                                                                                                                                                                                                                                                        gmaze_pv/subfct/diagVOLU.m                                                                          0000644 0023526 0000144 00000013733 10645460452 015010  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % [V,Cm,E,Vt,CC] = diagVOLU(FLAG,C1,C2,CLASS,LON,LAT,DPT,DV,[Ca(Z,Y,X),Cb(Z,Y,X),...])
%
% DESCRIPTION:
% Compute the volume of water for a particular CLASS of potential
% temperature or density.
% Also compute mean values of additional 3D fields (such as Ca, Cb ...) along
% the CLASS of the analysed field.
%
% The volume is accounted as:
%   CLASS(i) <= FIELD < CLASS(i+1)
%
% INPUTS: 
% FLAG    : Can either be: 0, 1 or 2
%           0: Compute volume of potential density classes
%              from C1=THETA and C2=SALT
%           1: Compute volume of potential density classes
%              from C1=SIGMA_THETA
%           2: Compute volume of temperature classes
%              from C1=THETA
% C1,C2   : Depends on option FLAG:
%           - FLAG = 0 : 
%                        C1 : Temperature (^oC)
%                        C2 : Salinity (PSU)
%           - FLAG = 1 : 
%                        C1 : Potential density (kg/m3) 
%                        C2 : Not used
%           - FLAG = 2 : 
%                        C1 : Temperature (^oC)
%                        C2 : Not used
% ClASS   : Range to explore (eg: [20:.1:30] for potential density)
% LON,LAT,DPT : axis (DPT < 0)
% dV      : Matrix of grid volume elements (m3) centered in (lon,lat,dpt) 
% Ca,Cb,...: Any additional 3D fields (unlimited)  
%
%
% OUTPUTS:
% V       : Volume of each CLASS (m3)
% Cm      : Mean value of the classified field (allow to check errors)
% E       : Each time a grid point is counted, a 1 is added to this 3D matrix
%           Allow to check double count of a point or unexplored areas
% Vt      : Is the total volume explored (Vt)
% CC      : Contains the mean value of additional fields Ca, Cb ....
%
% NOTES:
% - Fields are on the format: C(DPT,LAT,LON)
% - The potential density is computed with the equation of state routine from
%   the MITgcm called densjmd95.m 
%   (see: http://mitgcm.org/cgi-bin/viewcvs.cgi/MITgcm_contrib/gmaze_pv/subfct/densjmd95.m)
% - if dV is filled with NaN, dV is computed by the function
%
%
% AUTHOR: 
% Guillaume Maze / MIT 2006
% 
% HISTORY:
% - Created: 06/29/2007
%

% 

function varargout = diagVOLU(FLAG,C1,C2,CLASS,LON,LAT,DPT,DV,varargin)


% 0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREPROC
% Variables:
ndpt = size(C1,1);
nlat = size(C1,2);
nlon = size(C1,3);
CLASS = sort(CLASS(:));
[Z b c] = meshgrid(DPT,LON,LAT);clear b c, Z = permute(Z,[2 3 1]);

% Determine fields from which we'll take class contours:
switch FLAG
  
 case {0,2} % Need to compute SIGMA THETA
  THETA = C1;
  SALT  = C2;
  ST = densjmd95(SALT,THETA,0.09998*9.81*abs(Z)) - 1000; 
  if FLAG == 0     % Field is SIGMA THETA:
     CROP = ST;
  elseif FLAG == 2 % Field is THETA:
     CROP = THETA;
  end
  
 case 1
  ST = C1; % Potential density
  CROP = ST;
end
  
% Volume elements:
if length(find(isnan(DV)==1)) == ndpt*nlat*nlon
  if exist('subfct_getdV','file')
    DV = subfct_getdV(DPT,LAT,LON);
  else
    DV  = local_getdV(DPT,LAT,LON);
  end
end

% Need to compute volume integral over these 3D fields
nIN = nargin-8;
if nIN >= 1
  doEXTRA = 1;
else
  doEXTRA = 0;
end

% 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VOLUME INTEGRATION
explored = zeros(ndpt,nlat,nlon);
% Volume integral:
for iC = 1 : length(CLASS)-1
  mask   = zeros(ndpt,nlat,nlon);
  mask(find( (CLASS(iC) <= CROP) & (CROP < CLASS(iC+1)) )) = 1;
  explored = explored + mask;
  VOL(iC) = nansum(nansum(nansum(DV.*mask,1),2),3);
  
  if VOL(iC) ~= 0
     CAR(iC) = nansum(nansum(nansum(CROP.*DV.*mask,1),2),3)./VOL(iC);
     if doEXTRA
       for ii = 1 : nIN
           C = varargin{ii};
      	   CAREXTRA(ii,iC) = nansum(nansum(nansum(C.*DV.*mask,1),2),3)./VOL(iC);
       end %for ii	
     end %if doEXTRA
  else
     CAR(iC) = NaN;
     if doEXTRA
       for ii = 1 : nIN
      	   CAREXTRA(ii,iC) = NaN;
       end %for ii	
     end %if doEXTRA
  end  
end %for iC

% In order to compute the total volume of the domain:
CROP(find(isnan(CROP)==0)) = 1;  
CROP(find(isnan(CROP)==1)) = 0;
Vt = nansum(nansum(nansum(DV.*CROP,1),2),3);

% 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUTS
switch nargout
 case 1
  varargout(1) = {VOL};
 case 2
  varargout(1) = {VOL};
  varargout(2) = {CAR};
 case 3
  varargout(1) = {VOL};
  varargout(2) = {CAR};
  varargout(3) = {explored}; 
 case 4
  varargout(1) = {VOL};
  varargout(2) = {CAR};
  varargout(3) = {explored}; 
  varargout(4) = {Vt};
 case 5
  varargout(1) = {VOL};
  varargout(2) = {CAR};
  varargout(3) = {explored}; 
  varargout(4) = {Vt};
  varargout(5) = {CAREXTRA}; 
end %switch







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function computes the 3D dV volume elements.
% Copy of the subfct_getDV function from gmaze_pv package
function DV = local_getdV(Z,Y,X)

nz = length(Z);
ny = length(Y);
nx = length(X);

DV = zeros(nz,ny,nx);

% Vertical elements:
for iz = 1 : nz % Toward the deep ocean (because DPT<0)
	% Vertical grid length centered at Z(iy)
	if iz == 1
  	  dz = abs(Z(1)) + abs(sum(diff(Z(iz:iz+1))/2));
	elseif iz == nz % We don't know the real ocean depth
  	  dz = abs(sum(diff(Z(iz-1:iz))/2));
	else
  	  dz = abs(sum(diff(Z(iz-1:iz+1))/2));
        end
	DZ(iz) = dz;
end

% Surface and Volume elements:
for ix = 1 : nx
  for iy = 1 : ny
      % Zonal grid length centered in X(ix),Y(iY)
      if ix == 1
         dx = abs(m_lldist([X(ix) X(ix+1)],[1 1]*Y(iy)))/2;
      elseif ix == nx 
         dx = abs(m_lldist([X(ix-1) X(ix)],[1 1]*Y(iy)))/2;
      else
         dx = abs(m_lldist([X(ix-1) X(ix)],[1 1]*Y(iy)))/2+abs(m_lldist([X(ix) X(ix+1)],[1 1]*Y(iy)))/2;
      end	
 
      % Meridional grid length centered in X(ix),Y(iY)
      if iy == 1
        dy = abs(m_lldist([1 1]*X(ix),[Y(iy) Y(iy+1)]))/2;
      elseif iy == ny
        dy = abs(m_lldist([1 1]*X(ix),[Y(iy-1) Y(iy)]))/2;
      else	
        dy = abs(m_lldist([1 1]*X(ix),[Y(iy-1) Y(iy)]))/2+abs(m_lldist([1 1]*X(ix),[Y(iy) Y(iy+1)]))/2;
      end

      % Surface element:
      DA = dx*dy.*ones(1,nz);
      
      % Volume element:
      DV(:,iy,ix) = DZ.*DA;
  end %for iy
end %for ix

                                     gmaze_pv/subfct/dtecco2.m                                                                           0000644 0023526 0000144 00000002020 10650144563 014702  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % date = dtecco2(X,FORM)
%
% If: 
% FORM = 0, translate the stepnum X into a date string (yyyymmddHHMM)
% FORM = 1, translate the date string X (yyyymmddHHMM) into a stepnum
%
% 06/08/29
% gmaze@mit.edu
%

function varargout = dtecco2(varargin)

% Test inputs:
if nargin ~= 2
  help dtecco2.m
  error('dtecco2.m : Wrong number of parameters');
  return
end %if

% Recup inputs:
X = varargin{1};
FORM = varargin{2};

% New tests:
if FORM~=0 & FORM~=1
   help dtecco2.m
   error('dtecco2.m : Second argument must be 0 or 1');
   return
elseif FORM == 0 & ~isnumeric(X)
   help dtecco2.m
   error('dtecco2.m : if 2nd arg is 0, 1st arg must be numeric');
   return
elseif FORM == 1 & isnumeric(X)
   help dtecco2.m
   error('dtecco2.m : if 2nd arg is 1, 1st arg must be a string');
   return
end


% Let's go:
switch FORM
  
 case 0
  ID = datestr(datenum(1992,1,1)+X*300/60/60/24,'yyyymmddHHMM');
  varargout(1) = {ID};
  
 case 1
  ID = 60*60*24/300*( datenum(X,'yyyymmddHHMM') - datenum(1992,1,1) );
  varargout(1) = {ID};
  
  
end %switch
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                gmaze_pv/subfct/getFLUXbudgetV.m                                                                    0000644 0023526 0000144 00000013542 10650143163 016164  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % [D1,D2] = getFLUXbudgetV(z,y,x,Fx,Fy,Fz,box)
%
% Compute the two terms:
% D1 as the volume integral of the flux divergence
% D2 as the surface integral of the normal flux across the volume's boundary
%
% Given a 3D flux vector ie:
%  Fx(z,y,x)
%  Fy(z,y,x)
%  Fz(z,y,x)
%
% Defined on the C-grid at U,V,W locations (bounding the tracer point)
% given by:
% z ( = W detph )
% y ( = V latitude)
% x ( = U longitude)
%
% box is a 0/1 3D matrix defined on the tracer grid
% ie, of dimension: z-1 , y-1 , x-1
% 
% All fluxes are supposed to be scaled by the surface of the cell tile they
% account for.
%
% Each D is decomposed as: 
%  D(1) = Total integral (Vertical+Horizontal)
%  D(2) = Vertical contribution
%  D(3) = Horizontal contribution
%
% Rq:
% The divergence theorem is thus a conservation law which states that 
% the volume total of all sinks and sources, the volume integral of 
% the divergence, is equal to the net flow across the volume's boundary.
%
% gmaze@mit.edu 2007/07/19
%
%

function varargout = getFLUXbudgetV(varargin)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRELIM

dptw = varargin{1}; ndptw = length(dptw);
latg = varargin{2}; nlatg = length(latg);
long = varargin{3}; nlong = length(long);

ndpt = ndptw - 1;
nlon = nlong - 1;
nlat = nlatg - 1;

Fx = varargin{4};
Fy = varargin{5};
Fz = varargin{6};

if size(Fx,1) ~= ndpt
  disp('Error, Fx(1) wrong dim');
  return
end
if size(Fx,2) ~= nlatg-1
  disp('Error, Fx(2) wrong dim');
  whos Fx 
  return
end
if size(Fx,3) ~= nlong
  disp('Error, Fx(3) wrong dim');
  return
end

pii = varargin{7};

% Ensure we're not gonna missed points cause is messy around:
  Fx(isnan(Fx)) = 0;
  Fy(isnan(Fy)) = 0;
  Fz(isnan(Fz)) = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Compute the volume integral of flux divergence:
% (gonna be on the tracer grid)
dFdx = ( Fx(:,:,1:nlong-1) - Fx(:,:,2:nlong) );
dFdy = ( Fy(:,1:nlatg-1,:) - Fy(:,2:nlatg,:) );
dFdz = ( Fz(2:ndptw,:,:)   - Fz(1:ndptw-1,:,:) );
%whos dFdx dFdy dFdz

% And sum it over the box:
D1(1) = nansum(nansum(nansum( dFdx.*pii + dFdy.*pii + dFdz.*pii )));
D1(2) = nansum(nansum(nansum( dFdz.*pii )));
D1(3) = nansum(nansum(nansum( dFdy.*pii + dFdx.*pii )));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Compute the surface integral of the flux:
if nargout > 1
if exist('getVOLbounds')
  method = 3;
else
  method = 2;
end

switch method 
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%
 case 2
  bounds_W = zeros(ndpt,nlat,nlon);
  bounds_E = zeros(ndpt,nlat,nlon);
  bounds_S = zeros(ndpt,nlat,nlon);
  bounds_N = zeros(ndpt,nlat,nlon);
  bounds_T = zeros(ndpt,nlat,nlon);
  bounds_B = zeros(ndpt,nlat,nlon);
  Zflux = 0;
  Mflux = 0;
  Vflux = 0;

  for iz = 1 : ndpt
    for iy = 1 : nlat
      for ix = 1 : nlon
	if pii(iz,iy,ix) == 1
	  
	  % Is it a western boundary ?
	  if ix-1 <= 0 % Reach the domain limit
	    bounds_W(iz,iy,ix) = 1;
	    Zflux = Zflux + Fx(iz,iy,ix);
	  elseif pii(iz,iy,ix-1) == 0 
	    bounds_W(iz,iy,ix) = 1;
	    Zflux = Zflux + Fx(iz,iy,ix);
	  end
	  % Is it a eastern boundary ?
	  if ix+1 >= nlon % Reach the domain limit
	    bounds_E(iz,iy,ix) = 1;
	    Zflux = Zflux - Fx(iz,iy,ix+1);
	  elseif pii(iz,iy,ix+1) == 0
	    bounds_E(iz,iy,ix) = 1;
	    Zflux = Zflux - Fx(iz,iy,ix+1);
	  end
	  
	  % Is it a southern boundary ?
	  if iy-1 <= 0 % Reach the domain limit
	    bounds_S(iz,iy,ix) = 1;
	    Mflux = Mflux + Fy(iz,iy,ix);
	  elseif pii(iz,iy-1,ix) == 0
	    bounds_S(iz,iy,ix) = 1;
	    Mflux = Mflux + Fy(iz,iy,ix);
	  end
	  % Is it a northern boundary ?
	  if iy+1 >= nlat % Reach the domain limit
	    bounds_N(iz,iy,ix) = 1;
	    Mflux = Mflux - Fy(iz,iy+1,ix);
	  elseif pii(iz,iy+1,ix) == 0
	    bounds_N(iz,iy,ix) = 1;
	    Mflux = Mflux - Fy(iz,iy+1,ix);
	  end
	  
	  % Is it a top boundary ?
	  if iz-1 <= 0 % Reach the domain limit
	    bounds_T(iz,iy,ix) = 1;
	    Vflux = Vflux - Fz(iz,iy,ix);
	  elseif pii(iz-1,iy,ix) == 0
	    bounds_T(iz,iy,ix) = 1;
	    Vflux = Vflux - Fz(iz,iy,ix);
	  end
	  % Is it a bottom boundary ?
	  if iz+1 >= ndpt % Reach the domain limit
	    bounds_B(iz,iy,ix) = 1;
	    Vflux = Vflux + Fz(iz+1,iy,ix);
	  elseif pii(iz+1,iy,ix) == 0
	    bounds_B(iz,iy,ix) = 1;
	    Vflux = Vflux + Fz(iz+1,iy,ix);
	  end
	  
	end %for iy
      end %for ix	
       
    end
  end  
  
D2(1) = Vflux+Mflux+Zflux;
D2(2) = Vflux;
D2(3) = Mflux+Zflux;


%%%%%%%%%%%%%%%%%%%%
  case 3
  [bounds_N bounds_S bounds_W bounds_E bounds_T bounds_B] = getVOLbounds(pii);
  Mflux = nansum(nansum(nansum(...
      bounds_S.*squeeze(Fy(:,1:nlat,:)) - bounds_N.*squeeze(Fy(:,2:nlat+1,:)) )));
  Zflux = nansum(nansum(nansum(...
      bounds_W.*squeeze(Fx(:,:,1:nlon)) - bounds_E.*squeeze(Fx(:,:,2:nlon+1)) )));
  Vflux = nansum(nansum(nansum(...
      bounds_B.*squeeze(Fz(2:ndpt+1,:,:))-bounds_T.*squeeze(Fz(1:ndpt,:,:)) )));

  D2(1) = Vflux+Mflux+Zflux;
  D2(2) = Vflux;
  D2(3) = Mflux+Zflux;
  
end %switch method surface flux
end %if we realy need to compute this ?




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUTS


switch nargout
  case 1
varargout(1) = {D1};
  case 2
varargout(1) = {D1};
varargout(2) = {D2};
  case 3
varargout(1) = {D1};
varargout(2) = {D2};
varargout(3) = {bounds_N};
  case 4
varargout(1) = {D1};
varargout(2) = {D2};
varargout(3) = {bounds_N};
varargout(4) = {bounds_S};
  case 5
varargout(1) = {D1};
varargout(2) = {D2};
varargout(3) = {bounds_N};
varargout(4) = {bounds_S};
varargout(5) = {bounds_W};
  case 6
varargout(1) = {D1};
varargout(2) = {D2};
varargout(3) = {bounds_N};
varargout(4) = {bounds_S};
varargout(5) = {bounds_W};
varargout(6) = {bounds_E};
  case 7
varargout(1) = {D1};
varargout(2) = {D2};
varargout(3) = {bounds_N};
varargout(4) = {bounds_S};
varargout(5) = {bounds_W};
varargout(6) = {bounds_E};
varargout(7) = {bounds_T};
  case 8
varargout(1) = {D1};
varargout(2) = {D2};
varargout(3) = {bounds_N};
varargout(4) = {bounds_S};
varargout(5) = {bounds_W};
varargout(6) = {bounds_E};
varargout(7) = {bounds_T};
varargout(8) = {bounds_B};

end %switch                                                                                                                                                              gmaze_pv/subfct/getVOLbounds.m                                                                      0000644 0023526 0000144 00000005355 10650140675 015750  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % [BN BS BW BE BT BB] = getVOLbounds(PII)
%
% Given a 1/0 3D matrix PII, determine faces bounding the volume
% 
% INPUT:
%  PII is of dimensions: PII(NDPT,NLAT,NLON)
%  with:
%   DPT downward
%   LAT northward
%   LON eastward
%
% OUTPUT:
% BN,BS, BW,BE, BT,BB are 3D matrices like PII, filled with 0 or 1.
% 1 indicates a surface bounding the volume 
%
% BN stands for northern bound
% BS stands for southern bound
% BW stands for western bound
% BE stands for eastern bound
% BT stands for top bound
% BB stands for bottom bound
%
%  gmaze@mit.edu 2007/07/19
%

function varargout = getVOLbounds(varargin)


pii  = varargin{1};
ndpt = size(pii,1);
nlat = size(pii,2);
nlon = size(pii,3);


  bounds_W = zeros(ndpt,nlat,nlon);
  bounds_E = zeros(ndpt,nlat,nlon);
  bounds_S = zeros(ndpt,nlat,nlon);
  bounds_N = zeros(ndpt,nlat,nlon);
  bounds_T = zeros(ndpt,nlat,nlon);
  bounds_B = zeros(ndpt,nlat,nlon);

  for iz = 1 : ndpt
    for iy = 1 : nlat
      for ix = 1 : nlon
	if pii(iz,iy,ix) == 1
	  
	  % Is it a western boundary ?
	  if ix-1 <= 0 % Reach the domain limit
	    bounds_W(iz,iy,ix) = 1;
	  elseif pii(iz,iy,ix-1) == 0 
	    bounds_W(iz,iy,ix) = 1;
	  end
	  % Is it a eastern boundary ?
	  if ix+1 >= nlon % Reach the domain limit
	    bounds_E(iz,iy,ix) = 1;
	  elseif pii(iz,iy,ix+1) == 0
	    bounds_E(iz,iy,ix) = 1;
	  end
	  
	  % Is it a southern boundary ?
	  if iy-1 <= 0 % Reach the domain limit
	    bounds_S(iz,iy,ix) = 1;
	  elseif pii(iz,iy-1,ix) == 0
	    bounds_S(iz,iy,ix) = 1;
	  end
	  % Is it a northern boundary ?
	  if iy+1 >= nlat % Reach the domain limit
	    bounds_N(iz,iy,ix) = 1;
	  elseif pii(iz,iy+1,ix) == 0
	    bounds_N(iz,iy,ix) = 1;
	  end
	  
	  % Is it a top boundary ?
	  if iz-1 <= 0 % Reach the domain limit
	    bounds_T(iz,iy,ix) = 1;
	  elseif pii(iz-1,iy,ix) == 0
	    bounds_T(iz,iy,ix) = 1;
	  end
	  % Is it a bottom boundary ?
	  if iz+1 >= ndpt % Reach the domain limit
	    bounds_B(iz,iy,ix) = 1;
	  elseif pii(iz+1,iy,ix) == 0
	    bounds_B(iz,iy,ix) = 1;
	  end
	  
	end % if 
      end %for ix	
    end % for iy
  end % for iz
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUTS
switch nargout
  
  case 1
varargout(1) = {bounds_N};
  case 2
varargout(1) = {bounds_N};
varargout(2) = {bounds_S};
  case 3
varargout(1) = {bounds_N};
varargout(2) = {bounds_S};
varargout(3) = {bounds_W};
  case 4
varargout(1) = {bounds_N};
varargout(2) = {bounds_S};
varargout(3) = {bounds_W};
varargout(4) = {bounds_E};
  case 5
varargout(1) = {bounds_N};
varargout(2) = {bounds_S};
varargout(3) = {bounds_W};
varargout(4) = {bounds_E};
varargout(5) = {bounds_T};
  case 6
varargout(1) = {bounds_N};
varargout(2) = {bounds_S};
varargout(3) = {bounds_W};
varargout(4) = {bounds_E};
varargout(5) = {bounds_T};
varargout(6) = {bounds_B};

end %switch                                                                                                                                                                                                                                                                                   gmaze_pv/subfct/GRID_125.m                                                                          0000644 0023526 0000144 00000046127 10650144530 014505  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % THE 1/8 ORIGINAL GLOBAL GRID

 delR   = [ 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.01, ...
 10.03, 10.11, 10.32, 10.80, 11.76, 13.42, 16.04 , 19.82, 24.85, ...
 31.10, 38.42, 46.50, 55.00, 63.50, 71.58, 78.90, 85.15, 90.18, ...
 93.96, 96.58, 98.25, 99.25,100.01,101.33,104.56,111.33,122.83, ...
 139.09,158.94,180.83,203.55,226.50,249.50,272.50,295.50,318.50, ...
 341.50,364.50,387.50,410.50,433.50,456.50 ];
 phiMin=-78.6672;
 delY=[0.0247, 0.0247, 0.0247, 0.0248, 0.0248, 0.0248, 0.0249, 0.0250, ...
 0.0251, 0.0251, 0.0251, 0.0252, 0.0252, 0.0253, 0.0253, 0.0254, ...
 0.0255, 0.0255, 0.0255, 0.0256, 0.0257, 0.0257, 0.0258, 0.0258, ...
 0.0259, 0.0259, 0.0260, 0.0260, 0.0261, 0.0262, 0.0262, 0.0263, ...
 0.0264, 0.0264, 0.0264, 0.0265, 0.0266, 0.0266, 0.0267, 0.0267, ...
 0.0268, 0.0268, 0.0269, 0.0270, 0.0270, 0.0271, 0.0271, 0.0272, ...
 0.0272, 0.0273, 0.0274, 0.0274, 0.0275, 0.0275, 0.0276, 0.0276, ...
 0.0277, 0.0278, 0.0278, 0.0279, 0.0280, 0.0280, 0.0281, 0.0281, ...
 0.0282, 0.0282, 0.0283, 0.0284, 0.0285, 0.0285, 0.0285, 0.0286, ...
 0.0287, 0.0287, 0.0288, 0.0288, 0.0289, 0.0290, 0.0291, 0.0291, ...
 0.0291, 0.0292, 0.0293, 0.0294, 0.0294, 0.0294, 0.0295, 0.0296, ...
 0.0297, 0.0297, 0.0298, 0.0298, 0.0299, 0.0300, 0.0300, 0.0301, ...
 0.0302, 0.0302, 0.0303, 0.0304, 0.0304, 0.0305, 0.0306, 0.0306, ...
 0.0307, 0.0307, 0.0308, 0.0309, 0.0309, 0.0310, 0.0311, 0.0311, ...
 0.0312, 0.0313, 0.0314, 0.0314, 0.0314, 0.0315, 0.0316, 0.0317, ...
 0.0317, 0.0318, 0.0319, 0.0319, 0.0320, 0.0321, 0.0321, 0.0322, ...
 0.0323, 0.0323, 0.0324, 0.0325, 0.0326, 0.0326, 0.0327, 0.0327, ...
 0.0328, 0.0329, 0.0330, 0.0331, 0.0331, 0.0332, 0.0332, 0.0333, ...
 0.0334, 0.0334, 0.0335, 0.0336, 0.0337, 0.0337, 0.0338, 0.0339, ...
 0.0340, 0.0340, 0.0341, 0.0342, 0.0342, 0.0343, 0.0344, 0.0344, ...
 0.0345, 0.0346, 0.0347, 0.0347, 0.0348, 0.0349, 0.0350, 0.0350, ...
 0.0351, 0.0352, 0.0353, 0.0353, 0.0354, 0.0355, 0.0356, 0.0356, ...
 0.0357, 0.0358, 0.0359, 0.0359, 0.0360, 0.0361, 0.0362, 0.0362, ...
 0.0363, 0.0364, 0.0365, 0.0366, 0.0366, 0.0367, 0.0367, 0.0368, ...
 0.0369, 0.0370, 0.0371, 0.0371, 0.0372, 0.0373, 0.0374, 0.0375, ...
 0.0375, 0.0376, 0.0377, 0.0378, 0.0379, 0.0380, 0.0380, 0.0381, ...
 0.0381, 0.0382, 0.0383, 0.0384, 0.0385, 0.0386, 0.0387, 0.0388, ...
 0.0388, 0.0389, 0.0389, 0.0391, 0.0391, 0.0392, 0.0393, 0.0394, ...
 0.0395, 0.0395, 0.0396, 0.0397, 0.0398, 0.0399, 0.0400, 0.0400, ...
 0.0401, 0.0402, 0.0403, 0.0403, 0.0404, 0.0405, 0.0406, 0.0407, ...
 0.0408, 0.0409, 0.0409, 0.0410, 0.0411, 0.0412, 0.0413, 0.0414, ...
 0.0414, 0.0415, 0.0416, 0.0417, 0.0418, 0.0419, 0.0420, 0.0421, ...
 0.0421, 0.0422, 0.0423, 0.0424, 0.0425, 0.0426, 0.0427, 0.0428, ...
 0.0428, 0.0429, 0.0430, 0.0431, 0.0432, 0.0433, 0.0434, 0.0435, ...
 0.0435, 0.0436, 0.0437, 0.0438, 0.0439, 0.0440, 0.0441, 0.0442, ...
 0.0443, 0.0444, 0.0444, 0.0445, 0.0446, 0.0447, 0.0448, 0.0449, ...
 0.0450, 0.0451, 0.0452, 0.0453, 0.0453, 0.0454, 0.0455, 0.0456, ...
 0.0457, 0.0458, 0.0459, 0.0460, 0.0461, 0.0462, 0.0463, 0.0464, ...
 0.0465, 0.0466, 0.0466, 0.0468, 0.0468, 0.0470, 0.0471, 0.0471, ...
 0.0472, 0.0473, 0.0474, 0.0475, 0.0476, 0.0477, 0.0478, 0.0479, ...
 0.0480, 0.0481, 0.0482, 0.0483, 0.0484, 0.0485, 0.0486, 0.0487, ...
 0.0488, 0.0489, 0.0490, 0.0491, 0.0491, 0.0493, 0.0494, 0.0494, ...
 0.0495, 0.0496, 0.0498, 0.0498, 0.0499, 0.0501, 0.0502, 0.0502, ...
 0.0504, 0.0505, 0.0505, 0.0506, 0.0508, 0.0508, 0.0510, 0.0511, ...
 0.0512, 0.0513, 0.0514, 0.0515, 0.0516, 0.0517, 0.0518, 0.0519, ...
 0.0520, 0.0521, 0.0522, 0.0523, 0.0524, 0.0525, 0.0526, 0.0527, ...
 0.0528, 0.0529, 0.0530, 0.0532, 0.0533, 0.0533, 0.0534, 0.0536, ...
 0.0536, 0.0538, 0.0539, 0.0540, 0.0541, 0.0542, 0.0543, 0.0544, ...
 0.0545, 0.0546, 0.0548, 0.0548, 0.0549, 0.0551, 0.0552, 0.0552, ...
 0.0554, 0.0555, 0.0556, 0.0557, 0.0558, 0.0559, 0.0561, 0.0561, ...
 0.0562, 0.0564, 0.0565, 0.0566, 0.0567, 0.0568, 0.0569, 0.0570, ...
 0.0571, 0.0573, 0.0574, 0.0574, 0.0576, 0.0577, 0.0578, 0.0579, ...
 0.0581, 0.0581, 0.0583, 0.0583, 0.0585, 0.0586, 0.0587, 0.0588, ...
 0.0590, 0.0590, 0.0592, 0.0592, 0.0594, 0.0595, 0.0596, 0.0597, ...
 0.0599, 0.0600, 0.0601, 0.0602, 0.0603, 0.0604, 0.0606, 0.0606, ...
 0.0607, 0.0609, 0.0610, 0.0611, 0.0612, 0.0614, 0.0615, 0.0616, ...
 0.0617, 0.0618, 0.0619, 0.0621, 0.0622, 0.0623, 0.0624, 0.0625, ...
 0.0626, 0.0627, 0.0629, 0.0630, 0.0631, 0.0632, 0.0634, 0.0634, ...
 0.0636, 0.0637, 0.0639, 0.0639, 0.0640, 0.0641, 0.0643, 0.0644, ...
 0.0646, 0.0647, 0.0648, 0.0649, 0.0650, 0.0651, 0.0653, 0.0654, ...
 0.0656, 0.0656, 0.0657, 0.0659, 0.0660, 0.0661, 0.0663, 0.0663, ...
 0.0665, 0.0666, 0.0668, 0.0668, 0.0670, 0.0671, 0.0672, 0.0674, ...
 0.0675, 0.0676, 0.0678, 0.0678, 0.0680, 0.0681, 0.0682, 0.0683, ...
 0.0685, 0.0686, 0.0687, 0.0689, 0.0690, 0.0691, 0.0692, 0.0694, ...
 0.0695, 0.0696, 0.0698, 0.0698, 0.0700, 0.0701, 0.0703, 0.0703, ...
 0.0705, 0.0706, 0.0708, 0.0709, 0.0710, 0.0711, 0.0713, 0.0714, ...
 0.0715, 0.0716, 0.0718, 0.0719, 0.0721, 0.0721, 0.0723, 0.0724, ...
 0.0726, 0.0726, 0.0728, 0.0729, 0.0731, 0.0732, 0.0733, 0.0734, ...
 0.0736, 0.0737, 0.0738, 0.0740, 0.0741, 0.0742, 0.0744, 0.0745, ...
 0.0746, 0.0747, 0.0749, 0.0750, 0.0751, 0.0753, 0.0754, 0.0755, ...
 0.0757, 0.0758, 0.0759, 0.0761, 0.0762, 0.0763, 0.0765, 0.0766, ...
 0.0767, 0.0768, 0.0770, 0.0771, 0.0773, 0.0774, 0.0775, 0.0776, ...
 0.0778, 0.0779, 0.0781, 0.0782, 0.0783, 0.0784, 0.0786, 0.0787, ...
 0.0789, 0.0790, 0.0791, 0.0792, 0.0794, 0.0795, 0.0797, 0.0798, ...
 0.0799, 0.0800, 0.0802, 0.0803, 0.0805, 0.0806, 0.0807, 0.0808, ...
 0.0810, 0.0811, 0.0813, 0.0814, 0.0816, 0.0817, 0.0818, 0.0819, ...
 0.0821, 0.0822, 0.0824, 0.0825, 0.0826, 0.0827, 0.0829, 0.0830, ...
 0.0832, 0.0833, 0.0834, 0.0835, 0.0837, 0.0838, 0.0840, 0.0841, ...
 0.0842, 0.0844, 0.0845, 0.0846, 0.0848, 0.0849, 0.0851, 0.0852, ...
 0.0853, 0.0854, 0.0856, 0.0858, 0.0859, 0.0860, 0.0861, 0.0863, ...
 0.0864, 0.0865, 0.0867, 0.0868, 0.0870, 0.0871, 0.0872, 0.0873, ...
 0.0875, 0.0876, 0.0878, 0.0879, 0.0881, 0.0882, 0.0883, 0.0884, ...
 0.0886, 0.0887, 0.0889, 0.0890, 0.0892, 0.0893, 0.0894, 0.0895, ...
 0.0897, 0.0898, 0.0900, 0.0901, 0.0902, 0.0903, 0.0905, 0.0906, ...
 0.0908, 0.0909, 0.0911, 0.0912, 0.0913, 0.0914, 0.0916, 0.0917, ...
 0.0919, 0.0920, 0.0921, 0.0923, 0.0924, 0.0925, 0.0927, 0.0928, ...
 0.0930, 0.0931, 0.0932, 0.0933, 0.0935, 0.0936, 0.0938, 0.0939, ...
 0.0940, 0.0942, 0.0943, 0.0944, 0.0946, 0.0947, 0.0949, 0.0950, ...
 0.0951, 0.0952, 0.0954, 0.0955, 0.0957, 0.0958, 0.0959, 0.0960, ...
 0.0962, 0.0963, 0.0965, 0.0966, 0.0967, 0.0968, 0.0970, 0.0971, ...
 0.0973, 0.0974, 0.0975, 0.0976, 0.0978, 0.0979, 0.0981, 0.0982, ...
 0.0983, 0.0984, 0.0986, 0.0987, 0.0988, 0.0989, 0.0991, 0.0992, ...
 0.0994, 0.0995, 0.0997, 0.0998, 0.0999, 0.1000, 0.1002, 0.1003, ...
 0.1004, 0.1005, 0.1007, 0.1008, 0.1009, 0.1011, 0.1012, 0.1013, ...
 0.1015, 0.1016, 0.1017, 0.1018, 0.1020, 0.1021, 0.1023, 0.1024, ...
 0.1025, 0.1026, 0.1028, 0.1028, 0.1030, 0.1031, 0.1032, 0.1034, ...
 0.1035, 0.1036, 0.1037, 0.1039, 0.1040, 0.1041, 0.1043, 0.1044, ...
 0.1045, 0.1047, 0.1048, 0.1049, 0.1050, 0.1051, 0.1053, 0.1053, ...
 0.1055, 0.1056, 0.1058, 0.1058, 0.1060, 0.1061, 0.1063, 0.1063, ...
 0.1065, 0.1066, 0.1067, 0.1069, 0.1070, 0.1071, 0.1072, 0.1073, ...
 0.1075, 0.1075, 0.1077, 0.1078, 0.1079, 0.1081, 0.1082, 0.1083, ...
 0.1084, 0.1085, 0.1087, 0.1088, 0.1089, 0.1090, 0.1091, 0.1092, ...
 0.1093, 0.1095, 0.1096, 0.1097, 0.1098, 0.1099, 0.1100, 0.1102, ...
 0.1103, 0.1104, 0.1105, 0.1106, 0.1107, 0.1108, 0.1109, 0.1111, ...
 0.1112, 0.1113, 0.1114, 0.1115, 0.1116, 0.1117, 0.1118, 0.1119, ...
 0.1120, 0.1121, 0.1122, 0.1123, 0.1125, 0.1125, 0.1127, 0.1128, ...
 0.1129, 0.1130, 0.1131, 0.1132, 0.1133, 0.1134, 0.1135, 0.1136, ...
 0.1137, 0.1138, 0.1139, 0.1140, 0.1142, 0.1143, 0.1143, 0.1144, ...
 0.1146, 0.1147, 0.1147, 0.1149, 0.1150, 0.1151, 0.1151, 0.1152, ...
 0.1153, 0.1154, 0.1155, 0.1156, 0.1157, 0.1158, 0.1159, 0.1160, ...
 0.1161, 0.1162, 0.1163, 0.1164, 0.1164, 0.1166, 0.1166, 0.1167, ...
 0.1168, 0.1169, 0.1170, 0.1171, 0.1172, 0.1173, 0.1174, 0.1175, ...
 0.1175, 0.1176, 0.1177, 0.1178, 0.1179, 0.1180, 0.1180, 0.1181, ...
 0.1182, 0.1183, 0.1184, 0.1185, 0.1186, 0.1186, 0.1187, 0.1188, ...
 0.1189, 0.1190, 0.1190, 0.1191, 0.1192, 0.1193, 0.1194, 0.1194, ...
 0.1195, 0.1196, 0.1197, 0.1197, 0.1198, 0.1199, 0.1200, 0.1200, ...
 0.1201, 0.1202, 0.1203, 0.1203, 0.1204, 0.1204, 0.1205, 0.1206, ...
 0.1207, 0.1207, 0.1208, 0.1209, 0.1209, 0.1210, 0.1211, 0.1211, ...
 0.1212, 0.1213, 0.1214, 0.1214, 0.1214, 0.1215, 0.1216, 0.1216, ...
 0.1217, 0.1218, 0.1218, 0.1219, 0.1219, 0.1220, 0.1221, 0.1221, ...
 0.1222, 0.1222, 0.1223, 0.1223, 0.1224, 0.1224, 0.1225, 0.1225, ...
 0.1226, 0.1227, 0.1227, 0.1228, 0.1228, 0.1228, 0.1229, 0.1230, ...
 0.1230, 0.1231, 0.1231, 0.1231, 0.1232, 0.1232, 0.1233, 0.1233, ...
 0.1234, 0.1234, 0.1234, 0.1235, 0.1235, 0.1236, 0.1236, 0.1237, ...
 0.1237, 0.1237, 0.1238, 0.1238, 0.1238, 0.1239, 0.1239, 0.1240, ...
 0.1240, 0.1240, 0.1240, 0.1241, 0.1241, 0.1242, 0.1242, 0.1242, ...
 0.1242, 0.1243, 0.1243, 0.1243, 0.1243, 0.1244, 0.1244, 0.1245, ...
 0.1245, 0.1245, 0.1245, 0.1245, 0.1246, 0.1246, 0.1246, 0.1246, ...
 0.1246, 0.1247, 0.1247, 0.1247, 0.1247, 0.1247, 0.1248, 0.1248, ...
 0.1248, 0.1248, 0.1248, 0.1248, 0.1249, 0.1249, 0.1249, 0.1249, ...
 0.1249, 0.1249, 0.1249, 0.1249, 0.1249, 0.1249, 0.1250, 0.1249, ...
 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, ...
 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, 0.1250, ...
 0.1250, 0.1250, 0.1250, 0.1250, 0.1249, 0.1250, 0.1250, 0.1250, ...
 0.1250, 0.1249, 0.1249, 0.1249, 0.1249, 0.1249, 0.1249, 0.1249, ...
 0.1248, 0.1249, 0.1249, 0.1248, 0.1248, 0.1248, 0.1248, 0.1248, ...
 0.1248, 0.1247, 0.1247, 0.1247, 0.1246, 0.1247, 0.1246, 0.1246, ...
 0.1246, 0.1245, 0.1245, 0.1246, 0.1245, 0.1245, 0.1244, 0.1244, ...
 0.1244, 0.1244, 0.1243, 0.1243, 0.1242, 0.1243, 0.1242, 0.1242, ...
 0.1241, 0.1241, 0.1241, 0.1241, 0.1240, 0.1240, 0.1239, 0.1239, ...
 0.1239, 0.1239, 0.1238, 0.1238, 0.1237, 0.1237, 0.1236, 0.1236, ...
 0.1236, 0.1235, 0.1235, 0.1235, 0.1234, 0.1234, 0.1233, 0.1233, ...
 0.1232, 0.1232, 0.1231, 0.1231, 0.1230, 0.1230, 0.1230, 0.1229, ...
 0.1229, 0.1228, 0.1228, 0.1227, 0.1227, 0.1226, 0.1226, 0.1225, ...
 0.1224, 0.1224, 0.1223, 0.1223, 0.1222, 0.1222, 0.1221, 0.1220, ...
 0.1220, 0.1219, 0.1219, 0.1218, 0.1218, 0.1217, 0.1217, 0.1216, ...
 0.1215, 0.1214, 0.1214, 0.1213, 0.1213, 0.1212, 0.1211, 0.1211, ...
 0.1210, 0.1209, 0.1209, 0.1208, 0.1208, 0.1206, 0.1206, 0.1205, ...
 0.1205, 0.1204, 0.1203, 0.1202, 0.1202, 0.1201, 0.1200, 0.1200, ...
 0.1199, 0.1198, 0.1197, 0.1197, 0.1196, 0.1195, 0.1195, 0.1194, ...
 0.1193, 0.1192, 0.1191, 0.1190, 0.1189, 0.1189, 0.1188, 0.1187, ...
 0.1186, 0.1186, 0.1185, 0.1184, 0.1183, 0.1182, 0.1181, 0.1180, ...
 0.1180, 0.1178, 0.1178, 0.1177, 0.1177, 0.1176, 0.1174, 0.1174, ...
 0.1173, 0.1172, 0.1171, 0.1170, 0.1169, 0.1168, 0.1167, 0.1166, ...
 0.1166, 0.1164, 0.1164, 0.1163, 0.1162, 0.1161, 0.1160, 0.1159, ...
 0.1158, 0.1157, 0.1156, 0.1155, 0.1154, 0.1153, 0.1152, 0.1151, ...
 0.1151, 0.1150, 0.1149, 0.1147, 0.1147, 0.1146, 0.1144, 0.1143, ...
 0.1143, 0.1142, 0.1140, 0.1139, 0.1138, 0.1137, 0.1136, 0.1135, ...
 0.1134, 0.1133, 0.1132, 0.1131, 0.1130, 0.1129, 0.1128, 0.1127, ...
 0.1126, 0.1125, 0.1123, 0.1122, 0.1121, 0.1120, 0.1119, 0.1118, ...
 0.1117, 0.1116, 0.1115, 0.1114, 0.1113, 0.1112, 0.1110, 0.1109, ...
 0.1108, 0.1107, 0.1106, 0.1105, 0.1104, 0.1103, 0.1101, 0.1100, ...
 0.1099, 0.1098, 0.1097, 0.1096, 0.1095, 0.1093, 0.1092, 0.1091, ...
 0.1090, 0.1089, 0.1088, 0.1086, 0.1085, 0.1084, 0.1083, 0.1082, ...
 0.1081, 0.1079, 0.1078, 0.1077, 0.1076, 0.1075, 0.1073, 0.1072, ...
 0.1071, 0.1070, 0.1069, 0.1067, 0.1066, 0.1065, 0.1064, 0.1062, ...
 0.1061, 0.1060, 0.1059, 0.1057, 0.1056, 0.1055, 0.1054, 0.1052, ...
 0.1051, 0.1050, 0.1049, 0.1048, 0.1047, 0.1045, 0.1044, 0.1043, ...
 0.1041, 0.1040, 0.1039, 0.1037, 0.1036, 0.1035, 0.1034, 0.1032, ...
 0.1031, 0.1030, 0.1029, 0.1027, 0.1026, 0.1025, 0.1024, 0.1022, ...
 0.1021, 0.1020, 0.1019, 0.1017, 0.1016, 0.1014, 0.1013, 0.1012, ...
 0.1011, 0.1010, 0.1008, 0.1007, 0.1005, 0.1004, 0.1003, 0.1001, ...
 0.1000, 0.0999, 0.0998, 0.0996, 0.0995, 0.0994, 0.0993, 0.0991, ...
 0.0989, 0.0988, 0.0987, 0.0986, 0.0985, 0.0983, 0.0982, 0.0980, ...
 0.0979, 0.0978, 0.0977, 0.0975, 0.0974, 0.0972, 0.0971, 0.0970, ...
 0.0969, 0.0967, 0.0966, 0.0964, 0.0963, 0.0962, 0.0961, 0.0959, ...
 0.0958, 0.0956, 0.0955, 0.0954, 0.0953, 0.0951, 0.0950, 0.0948, ...
 0.0947, 0.0946, 0.0944, 0.0943, 0.0942, 0.0940, 0.0939, 0.0938, ...
 0.0936, 0.0935, 0.0934, 0.0932, 0.0931, 0.0929, 0.0928, 0.0927, ...
 0.0925, 0.0924, 0.0923, 0.0921, 0.0920, 0.0919, 0.0918, 0.0916, ...
 0.0914, 0.0913, 0.0912, 0.0910, 0.0909, 0.0908, 0.0906, 0.0905, ...
 0.0904, 0.0902, 0.0901, 0.0899, 0.0898, 0.0897, 0.0896, 0.0894, ...
 0.0893, 0.0891, 0.0890, 0.0889, 0.0887, 0.0886, 0.0885, 0.0883, ...
 0.0882, 0.0880, 0.0879, 0.0878, 0.0876, 0.0875, 0.0874, 0.0872, ...
 0.0871, 0.0869, 0.0868, 0.0867, 0.0866, 0.0864, 0.0863, 0.0861, ...
 0.0860, 0.0859, 0.0857, 0.0856, 0.0855, 0.0853, 0.0852, 0.0850, ...
 0.0849, 0.0848, 0.0846, 0.0845, 0.0844, 0.0842, 0.0841, 0.0840, ...
 0.0838, 0.0837, 0.0836, 0.0834, 0.0833, 0.0831, 0.0830, 0.0829, ...
 0.0828, 0.0826, 0.0825, 0.0823, 0.0822, 0.0821, 0.0819, 0.0818, ...
 0.0817, 0.0815, 0.0814, 0.0813, 0.0811, 0.0810, 0.0809, 0.0807, ...
 0.0806, 0.0804, 0.0803, 0.0802, 0.0801, 0.0799, 0.0798, 0.0796, ...
 0.0795, 0.0794, 0.0793, 0.0791, 0.0790, 0.0788, 0.0787, 0.0786, ...
 0.0785, 0.0783, 0.0782, 0.0781, 0.0779, 0.0778, 0.0776, 0.0775, ...
 0.0774, 0.0773, 0.0771, 0.0770, 0.0768, 0.0767, 0.0766, 0.0765, ...
 0.0763, 0.0762, 0.0760, 0.0759, 0.0758, 0.0757, 0.0755, 0.0754, ...
 0.0753, 0.0751, 0.0750, 0.0749, 0.0748, 0.0746, 0.0745, 0.0744, ...
 0.0742, 0.0741, 0.0739, 0.0738, 0.0737, 0.0736, 0.0735, 0.0733, ...
 0.0732, 0.0730, 0.0729, 0.0728, 0.0727, 0.0725, 0.0724, 0.0723, ...
 0.0722, 0.0720, 0.0719, 0.0718, 0.0717, 0.0715, 0.0714, 0.0713, ...
 0.0711, 0.0710, 0.0708, 0.0707, 0.0706, 0.0705, 0.0704, 0.0702, ...
 0.0701, 0.0700, 0.0699, 0.0697, 0.0696, 0.0695, 0.0694, 0.0692, ...
 0.0691, 0.0690, 0.0689, 0.0687, 0.0686, 0.0685, 0.0684, 0.0683, ...
 0.0681, 0.0680, 0.0678, 0.0677, 0.0676, 0.0675, 0.0674, 0.0672, ...
 0.0671, 0.0670, 0.0669, 0.0667, 0.0666, 0.0665, 0.0664, 0.0662, ...
 0.0661, 0.0660, 0.0659, 0.0658, 0.0656, 0.0655, 0.0654, 0.0653, ...
 0.0652, 0.0650, 0.0649, 0.0648, 0.0647, 0.0646, 0.0644, 0.0643, ...
 0.0641, 0.0640, 0.0639, 0.0639, 0.0637, 0.0636, 0.0634, 0.0633, ...
 0.0632, 0.0631, 0.0630, 0.0629, 0.0628, 0.0626, 0.0625, 0.0624, ...
 0.0623, 0.0622, 0.0621, 0.0619, 0.0618, 0.0617, 0.0616, 0.0615, ...
 0.0613, 0.0612, 0.0611, 0.0610, 0.0609, 0.0608, 0.0606, 0.0605, ...
 0.0604, 0.0603, 0.0602, 0.0601, 0.0600, 0.0598, 0.0597, 0.0596, ...
 0.0595, 0.0594, 0.0592, 0.0592, 0.0590, 0.0589, 0.0588, 0.0587, ...
 0.0586, 0.0585, 0.0584, 0.0583, 0.0581, 0.0581, 0.0579, 0.0578, ...
 0.0577, 0.0576, 0.0574, 0.0574, 0.0572, 0.0571, 0.0570, 0.0569, ...
 0.0568, 0.0567, 0.0566, 0.0565, 0.0564, 0.0562, 0.0561, 0.0561, ...
 0.0559, 0.0558, 0.0557, 0.0556, 0.0555, 0.0554, 0.0552, 0.0552, ...
 0.0551, 0.0549, 0.0548, 0.0547, 0.0546, 0.0545, 0.0544, 0.0543, ...
 0.0542, 0.0541, 0.0540, 0.0539, 0.0538, 0.0536, 0.0536, 0.0534, ...
 0.0533, 0.0533, 0.0532, 0.0530, 0.0529, 0.0528, 0.0527, 0.0526, ...
 0.0525, 0.0524, 0.0523, 0.0522, 0.0521, 0.0520, 0.0519, 0.0518, ...
 0.0517, 0.0516, 0.0515, 0.0514, 0.0513, 0.0512, 0.0511, 0.0510, ...
 0.0508, 0.0508, 0.0506, 0.0505, 0.0505, 0.0504, 0.0502, 0.0502, ...
 0.0501, 0.0499, 0.0498, 0.0498, 0.0496, 0.0495, 0.0494, 0.0494, ...
 0.0493, 0.0491, 0.0491, 0.0490, 0.0489, 0.0488, 0.0487, 0.0486, ...
 0.0485, 0.0484, 0.0483, 0.0482, 0.0481, 0.0480, 0.0479, 0.0478, ...
 0.0477, 0.0476, 0.0475, 0.0474, 0.0474, 0.0472, 0.0471, 0.0471, ...
 0.0470, 0.0468, 0.0468, 0.0466, 0.0465, 0.0465, 0.0464, 0.0463, ...
 0.0462, 0.0461, 0.0460, 0.0459, 0.0458, 0.0457, 0.0457, 0.0455, ...
 0.0454, 0.0453, 0.0452, 0.0452, 0.0451, 0.0450, 0.0449, 0.0448, ...
 0.0447, 0.0446, 0.0446, 0.0444, 0.0444, 0.0443, 0.0442, 0.0441, ...
 0.0440, 0.0439, 0.0438, 0.0437, 0.0436, 0.0435, 0.0434, 0.0434, ...
 0.0433, 0.0432, 0.0431, 0.0430, 0.0430, 0.0429, 0.0427, 0.0427, ...
 0.0426, 0.0425, 0.0424, 0.0423, 0.0422, 0.0421, 0.0421, 0.0419, ...
 0.0419, 0.0418, 0.0417, 0.0416, 0.0415, 0.0414, 0.0414, 0.0412, ...
 0.0412, 0.0411, 0.0410, 0.0410, 0.0409, 0.0407, 0.0407, 0.0406, ...
 0.0406, 0.0404, 0.0403, 0.0403, 0.0402, 0.0401, 0.0400, 0.0400, ...
 0.0399, 0.0398, 0.0397, 0.0396, 0.0395, 0.0394, 0.0394, 0.0393, ...
 0.0392, 0.0391, 0.0391, 0.0389, 0.0389, 0.0388, 0.0388, 0.0387, ...
 0.0386, 0.0384, 0.0384, 0.0383, 0.0382, 0.0382, 0.0381, 0.0380, ...
 0.0380, 0.0378, 0.0378, 0.0377, 0.0376, 0.0375, 0.0375, 0.0373, ...
 0.0373, 0.0372, 0.0372, 0.0370, 0.0370, 0.0369, 0.0369, 0.0367, ...
 0.0367, 0.0366, 0.0366, 0.0364, 0.0364, 0.0363, 0.0363, 0.0362, ...
 0.0361, 0.0360, 0.0359, 0.0358, 0.0358, 0.0357, 0.0357, 0.0356, ...
 0.0355, 0.0354, 0.0354, 0.0353, 0.0352, 0.0351, 0.0350, 0.0350, ...
 0.0349, 0.0348, 0.0347, 0.0346, 0.0346, 0.0345, 0.0344, 0.0343, ...
 0.0343, 0.0342, 0.0342, 0.0341, 0.0341, 0.0339, 0.0339, 0.0338, ...
 0.0338, 0.0336, 0.0336, 0.0335, 0.0335, 0.0334, 0.0333, 0.0332, ...
 0.0332, 0.0331, 0.0331, 0.0330, 0.0329, 0.0328, 0.0327, 0.0327, ...
 0.0326, 0.0325, 0.0325, 0.0324, 0.0323, 0.0323, 0.0322, 0.0321, ...
 0.0321, 0.0320, 0.0320, 0.0319, 0.0318, 0.0317, 0.0317, 0.0316, ...
 0.0315, 0.0314, 0.0314, 0.0314, 0.0313, 0.0312, 0.0311, 0.0310, ...
 0.0310, 0.0310, 0.0309, 0.0308, 0.0307, 0.0307, 0.0306, 0.0305, ...
 0.0305, 0.0304, 0.0304, 0.0303, 0.0303, 0.0301, 0.0301, 0.0301, ...
 0.0300, 0.0299, 0.0298, 0.0298, 0.0297, 0.0297, 0.0296, 0.0295, ...
 0.0294, 0.0294, 0.0294, 0.0293, 0.0292, 0.0291, 0.0291, 0.0290, ...
 0.0290, 0.0289, 0.0289, 0.0288, 0.0287, 0.0287, 0.0286, 0.0285, ...
 0.0285, 0.0284, 0.0284, 0.0283, 0.0283, 0.0282, 0.0281, 0.0281, ...
 0.0280, 0.0279, 0.0279, 0.0278, 0.0278, 0.0277, 0.0277, 0.0276, ...
 0.0275, 0.0275, 0.0274, 0.0274, 0.0273, 0.0272, 0.0271, 0.0271, ...
 0.0271, 0.0270, 0.0270, 0.0269, 0.0269, 0.0268, 0.0267, 0.0267, ...
 0.0266, 0.0265, 0.0265, 0.0264, 0.0264, 0.0264, 0.0263, 0.0262, ...
 0.0261, 0.0261, 0.0261, 0.0260, 0.0259, 0.0259, 0.0258, 0.0258, ...
 0.0257, 0.0257, 0.0256, 0.0255, 0.0255, 0.0254, 0.0254, 0.0253, ...
 0.0253, 0.0252, 0.0252, 0.0251, 0.0251, 0.0250, 0.0250, 0.0249, ...
 0.0249, 0.0248, 0.0248, 0.0247, 0.0246, 0.0246, 0.0245, 0.0245, ...
 0.0244, 0.0244, 0.0243, 0.0243, 0.0242, 0.0242, 0.0241, 0.0241, ...
 0.0240, 0.0240, 0.0239, 0.0239, 0.0238, 0.0238, 0.0237, 0.0237, ...
 0.0236, 0.0236, 0.0235, 0.0235, 0.0234, 0.0234, 0.0233, 0.0233, ...
 0.0232, 0.0232, 0.0231, 0.0231, 0.0230, 0.0230, 0.0229, 0.0229, ...
 0.0228, 0.0228, 0.0227, 0.0227, 0.0226, 0.0226, 0.0225, 0.0225, ...
 0.0224, 0.0224, 0.0223, 0.0223, 0.0222, 0.0222, 0.0221, 0.0221, ...
 0.0220, 0.0220, 0.0219, 0.0219, 0.0219, 0.0218, 0.0218, 0.0218];
 delX=ones(2880,1)*.125;

top=[0 cumsum(delR(1:(length(delR)-1)))];
bot=cumsum(delR);
thk125=bot-top;
dpt125=(top+bot)/2;

top=[0 cumsum(delX(1:(length(delX)-1)))'];
bot=cumsum(delX)';
lon125=(top+bot)/2;

top=[phiMin phiMin+cumsum(delY(1:(length(delY)-1)))];
bot=phiMin+cumsum(delY);
lat125=(top+bot)/2;

clear top bot del* phi*
                                                                                                                                                                                                                                                                                                                                                                                                                                         gmaze_pv/subfct/latlon2ingrid_netcdf.m                                                              0000644 0023526 0000144 00000011113 10650144456 017456  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % latlon2ingrid_netcdf: Read a bin snapshot from 1/8 simu and record it as netcdf
% latlon2ingrid_netcdf(pathname,pathout, ...
%                            stepnum,fpref,otab,           ...
%                            lon_c, lon_u,                    ...
%                            lat_c, lat_v,                    ...
%                            z_c, z_w,                        ...
%                            subname,                         ...
%                            lonmin,lonmax,latmin,latmax,depmin,depmax);

function latlon2ingrid_netcdf(pathname,pathout, ...
                            stepnum,fpref,otab,           ...
                            lon_c, lon_u,                    ...
                            lat_c, lat_v,                    ...
                            z_c, z_w,                        ...
                            subname,                         ...
                            lonmin,lonmax,latmin,latmax,depmin,depmax);

irow=strmatch({fpref},otab(:,1),'exact');
if length(irow) ~= 1
 fprintf('Bad irow value in latlon2ingrid_netcdf2\n');
 return
end
loc=otab{irow,3};
id=otab{irow,4};
units=otab{irow,5};
dimspec=otab{irow,2};
if strmatch(id,'unknown_id','exact')
 id = fpref;
end
fprintf('Field %s, loc=%s, id=%s, units=%s, dimspec=%s\n',fpref,loc,id,units,dimspec);
wordlen=otab{irow,6};
if wordlen == 4
 numfmt='float32';
end
if wordlen == 8
 numfmt='float64';
end
%numfmt='float64';
%wordlen =8;

%ilo_c=min(find(lon_c  >= lonmin & lon_c  <= lonmax));
%ilo_u=min(find(lon_u  >= lonmin & lon_u  <= lonmax));
%ihi_c=max(find(lon_c  >= lonmin & lon_c  <= lonmax));
%ihi_u=max(find(lon_u  >= lonmin & lon_u  <= lonmax));
ilo_c=min(find(lon_c-180 >= lonmin & lon_c-180 <= lonmax));
ilo_u=min(find(lon_u-180 >= lonmin & lon_u-180 <= lonmax));
ihi_c=max(find(lon_c-180 >= lonmin & lon_c-180 <= lonmax));
ihi_u=max(find(lon_u-180 >= lonmin & lon_u-180 <= lonmax));
jlo_c=min(find(lat_c >= latmin & lat_c <= latmax));
jlo_v=min(find(lat_v >= latmin & lat_v <= latmax));
jhi_c=max(find(lat_c >= latmin & lat_c <= latmax));
jhi_v=max(find(lat_v >= latmin & lat_v <= latmax));
klo_w=min(find(z_w   >= depmin & z_w   <= depmax));
khi_w=max(find(z_w   >= depmin & z_w   <= depmax));
klo_c=min(find(z_c   >= depmin & z_c   <= depmax));
khi_c=max(find(z_c   >= depmin & z_c   <= depmax));

fnam=sprintf('%s.%10.10d.data',fpref,stepnum);
if loc == 'c'
 ilo=ilo_c;
 ihi=ihi_c;
 jlo=jlo_c;
 jhi=jhi_c;
 klo=klo_c;
 khi=khi_c;
 lon=lon_c;
 lat=lat_c;
 dep=-z_c;
end
if loc == 'u'
 ilo=ilo_u;
 ihi=ihi_u;
 jlo=jlo_c;
 jhi=jhi_c;
 klo=klo_c;
 khi=khi_c;
 lon=lon_u;
 lat=lat_c;
 dep=-z_c;
end
if loc == 'v'
 ilo=ilo_c;
 ihi=ihi_c;
 jlo=jlo_v;
 jhi=jhi_v;
 klo=klo_c;
 khi=khi_c;
 lon=lon_c;
 lat=lat_v;
 dep=-z_c;
end
if loc == 'w'
 ilo=ilo_c;
 ihi=ihi_c;
 jlo=jlo_c;
 jhi=jhi_c;
 klo=klo_w;
 khi=khi_w;
 lon=lon_c;
 lat=lat_v;
 dep=-z_w;
end

nx=1;ny=1;nz=1;
if strmatch(dimspec,'xyz','exact');
 nx=length(lon);
 ny=length(lat);
 nz=length(dep);
end
if strmatch(dimspec,'xy','exact');
 nx=length(lon);
 ny=length(lat);
end

if klo > nz
 klo = nz;
end
if khi > nz
 khi = nz;
end

phiXYZ=zeros(ihi-ilo+1,jhi-jlo+1,khi-klo+1,'single');
disp(strcat('in:',pathname,fnam))
%[klo khi khi-klo+1]

% Read a single level (selected by k)
for k = klo : khi
 fid           = fopen(strcat(pathname,fnam),'r','ieee-be');
 fseek(fid,(k-1)*nx*ny*wordlen,'bof');
 phi           = fread(fid,nx*ny,numfmt); 
 %whos phi, [k nx ny]
 phiXY         = reshape(phi,[nx ny]);
 phiXY         = phiXY(ilo:ihi,jlo:jhi);
 phiXYZ(:,:,k) = phiXY;
 %phiXYZ(100,100,k)
 fclose(fid);
end

%%%clear phi;
%%%clear phiXY;
phiXYZ(find(phiXYZ==0))=NaN;

if subname == ' '
 %outname=sprintf('%s.nc',id);
 outname = sprintf('%s.nc',otab{irow,1});
else
 %outname=sprintf('%s_%s.nc',subname,id);
 outname = sprintf('%s.%s.nc',otab{irow,1},subname);
 %outname = sprintf('%s.%s.nc',strcat(otab{irow,1},'s'),subname);

end
nc = netcdf(strcat(pathout,outname),'clobber');
%disp(strcat(pathout,outname))

nc('X')=ihi-ilo+1;
nc('Y')=jhi-jlo+1;
nc('Z')=khi-klo+1;

nc{'X'}='X';
nc{'Y'}='Y';
nc{'Z'}='Z';

nc{'X'}.uniquename='X';
nc{'X'}.long_name='longitude';
nc{'X'}.gridtype=ncint(0);
nc{'X'}.units='degrees_east';
nc{'X'}(:) = lon(ilo:ihi);

nc{'Y'}.uniquename='Y';
nc{'Y'}.long_name='latitude';
nc{'Y'}.gridtype=ncint(0);
nc{'Y'}.units='degrees_north';
nc{'Y'}(:) = lat(jlo:jhi);

nc{'Z'}.uniquename='Z';
nc{'Z'}.long_name='depth';
nc{'Z'}.gridtype=ncint(0);
nc{'Z'}.units='m';
nc{'Z'}(:) = dep(klo:khi);

ncid=id;
nc{ncid}={'Z' 'Y' 'X'};
nc{ncid}.missing_value = ncdouble(NaN);
nc{ncid}.FillValue_ = ncdouble(0.0);
nc{ncid}(:,:,:) = permute(phiXYZ,[3 2 1]);
nc{ncid}.units=units;

close(nc);
                                                                                                                                                                                                                                                                                                                                                                                                                                                     gmaze_pv/subfct/latlon8grid_outputs_table.m                                                         0000644 0023526 0000144 00000011113 10650144325 020557  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  function otab = latlon8grid_outputs_table

% otab = latlon8grid_outputs_table()
% Output Fields from 1/8 simulations
% 1 - file prefix
% 2 - dimensions
% 3 - grid location
% 4 - id string (defaults to file prefix if unknown)
% 5 - units
% 6 - bytes per value


otab=[{'AREAtave'},   {'xy'}, {'c'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'ETAN'},       {'xy'}, {'c'}, {'ssh'}, {'m'}, {4},
      {'ETANSQ'},     {'xy'}, {'c'}, {'ssh_squared'}, {'m^2'}, {4},
      {'EXFhl'},      {'xy'}, {'c'}, {'latent_heat_flux'}, {'W/m^2'}, {4},
      {'EXFhs'},      {'xy'}, {'c'}, {'sensible_heat_flux'}, {'W/m^2'}, {4},
      {'EXFlw'},      {'xy'}, {'c'}, {'longwave_radiation'}, {'W/m^2'}, {4},
      {'EXFsw'},      {'xy'}, {'c'}, {'shortwave_radiation'}, {'W/m^2'}, {4},
      {'EmPmRtave'},  {'xy'}, {'c'}, {'net_evaporation'}, {'m/s'}, {4},
      {'FUtave'},     {'xy'}, {'c'}, {'averaged_zonal_stress'}, {'N/m^2'}, {4},
      {'FVtave'},     {'xy'}, {'c'}, {'averaged_meridional_stress'}, {'N/m^2'}, {4},
      {'HEFFtave'},   {'xy'}, {'c'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'KPPhbl'},     {'xy'}, {'c'}, {'thermocline_base'}, {'m'}, {4},
      {'KPPmld'},     {'xy'}, {'c'}, {'mixed_layer_depth'}, {'m'}, {4},
      {'PHIBOT'},     {'xy'}, {'c'}, {'bottom_pressure'}, {'Pa'}, {4},
      {'QNETtave'},   {'xy'}, {'c'}, {'averaged_net_heatflux'}, {'W/m^2'}, {4},
      {'QSWtave'},    {'xy'}, {'c'}, {'averaged_shortwave_heatflux'}, {'W/m^2'}, {4},
      {'SFLUX'},      {'xy'}, {'c'}, {'salinity_flux'}, {'psu/s'}, {4},
      {'SRELAX'},     {'xy'}, {'c'}, {'salinity_relaxation'}, {'psu/s'}, {4},
      {'SSS'},        {'xy'}, {'c'}, {'sea_surface_salinity'}, {'psu'}, {4},
      {'SST'},        {'xy'}, {'c'}, {'sea_surface_temperature'}, {'degrees_centigrade'}, {4},
      {'TAUX'},       {'xy'}, {'c'}, {'zonal_wind_stress'}, {'N/m^2'}, {4},
      {'TAUY'},       {'xy'}, {'c'}, {'meridional_wind_stress'}, {'N/m^2'}, {4},
      {'TFLUX'},      {'xy'}, {'c'}, {'temperature_flux'}, {'W/m^2'}, {4},
      {'TICE'},       {'xy'}, {'c'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'UICEtave'},   {'xy'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'UVEL_k2'},    {'xy'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VICEtave'},   {'xy'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VVEL_k2'},    {'xy'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'DRHODR'},    {'xyz'}, {'w'}, {'vertical_density_gradient'}, {'kg/m^4'}, {4},
      {'RHOANOSQ'},  {'xyz'}, {'c'}, {'density_anomaly_squared'}, {'(kg/m^3-1000)^2'}, {4},
      {'RHOAnoma'},  {'xyz'}, {'c'}, {'density_anomaly'}, {'kg/m^3-1000'}, {8},
      {'SALTSQan'},  {'xyz'}, {'c'}, {'salinity_anomaly_squared'}, {'(psu-35)^2'}, {4},
      {'SALTanom'},  {'xyz'}, {'c'}, {'salinity_anomaly'}, {'psu-35'}, {8},
      {'THETA'},     {'xyz'}, {'c'}, {'potential_temperature'}, {'degrees_centigrade'}, {8},
      {'THETASQ'},   {'xyz'}, {'c'}, {'potential_temperature_squared'}, {'degrees_centigrade^2'}, {8},
      {'URHOMASS'},  {'xyz'}, {'u'}, {'zonal_mass_transport'}, {'kg.m^3/s'}, {4},
      {'USLTMASS'},  {'xyz'}, {'u'}, {'zonal_salt_transport'}, {'psu.m^3/s'}, {4},
      {'UTHMASS'},   {'xyz'}, {'u'}, {'zonal_temperature_transport'}, {'degrees_centigrade.m^3/s'}, {4},
      {'UVEL'},      {'xyz'}, {'u'}, {'zonal_flow'}, {'m/s'}, {4},
      {'UVELMASS'},  {'xyz'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'UVELSQ'},    {'xyz'}, {'u'}, {'zonal_flow_squared'}, {'(m/s)^2'}, {4},
      {'UV_VEL_Z'},  {'xyz'}, {'u'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VISCA4'},    {'xyz'}, {'c'}, {'biharmonic_viscosity'}, {'m^4/s'}, {4},
      {'VRHOMASS'},  {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VSLTMASS'},  {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VTHMASS'},   {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VVEL'},      {'xyz'}, {'v'}, {'meridional_velocity'}, {'m/s'}, {4},
      {'VVELMASS'},  {'xyz'}, {'v'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'VVELSQ'},    {'xyz'}, {'v'}, {'meridional_velocity_squared'}, {'(m/s)^2'}, {4},
      {'WRHOMASS'},  {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WSLTMASS'},  {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WTHMASS'},   {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WU_VEL'},    {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WVELMASS'},  {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WVELSQ'},    {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4},
      {'WV_VEL'},    {'xyz'}, {'w'}, {'unknown_id'}, {'unknown_units'}, {4}];

                                                                                                                                                                                                                                                                                                                                                                                                                                                     gmaze_pv/subfct/readrec_cs510.m                                                                     0000644 0023526 0000144 00000000641 10557736031 015711  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % C = READREC_CS510(fnam,NZ,fldprec)
%
% Get one record from the CS510 run
%
% fnam : string to the file (include path)
% NZ   : number of levels to read
% fldprec : float32 or float64
% ouput is: C(510,510,NZ,6)
%
%

function C = readrec_cs510(fnam,NZ,fldprec)

fmt = 'ieee-be';
nx  = 510;
ny  = 510;


fid  = fopen(fnam,'r',fmt);
C    = fread(fid,6*nx*ny*NZ,fldprec);
fclose(fid);
C    = reshape(C,[6*nx ny NZ]);


                                                                                               gmaze_pv/subfct/subfct_getdS.m                                                                      0000644 0023526 0000144 00000001216 10650144121 015767  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % DS = subfct_getdS(LAT,LON)
% This function computes the 2D dS surface elements centered
% on LON,LAT
%

function ds = subfct_getdS(Y,X);

ny = length(Y);
nx = length(X);

if nx == size(X,1)
  X = X';
end
if ny == size(Y,1)
  Y = Y';
end

%%% Compute the DY:
% Assuming Y is independant of ix:
d  = m_lldist([1 1]*X(1),Y);
dy = [d(1)/2  (d(2:length(d))+d(1:length(d)-1))/2 d(length(d))/2];
dy = meshgrid(dy,X)';

%%% Compute the DX:
clear d
for iy = 1 : ny
   d(:,iy) = m_lldist(X,Y([iy iy]));
end
dx = [d(1,:)/2 ;  ( d(2:size(d,1),:) + d(1:size(d,1)-1,:) )./2 ; d(size(d,1),:)/2];
dx = dx';

%% Compute the horizontal DS surface element:
ds = dx.*dy;

                                                                                                                                                                                                                                                                                                                                                                                  gmaze_pv/subfct/subfct_getdV.m                                                                      0000644 0023526 0000144 00000002707 10650144103 016000  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % DV = subfct_getdV(DEPTH,LATITUDE,LONGITUDE)
% Compute 3D volume elements matrix from geographical
% axis Z(<0,downward), Y and X

function DV = subfct_getdV(Z,Y,X)

nz = length(Z);
ny = length(Y);
nx = length(X);

DV = zeros(nz,ny,nx);

% Vertical elements:
for iz = 1 : nz % Toward the deep ocean (because DPT<0)
	% Vertical grid length centered at Z(iy)
	if iz == 1
  	  dz = abs(Z(1)) + abs(sum(diff(Z(iz:iz+1))/2));
	elseif iz == nz % We don't know the real ocean depth
  	  dz = abs(sum(diff(Z(iz-1:iz))/2));
	else
  	  dz = abs(sum(diff(Z(iz-1:iz+1))/2));
        end
	DZ(iz) = dz;
end

% Surface and Volume elements:
for ix = 1 : nx
  for iy = 1 : ny
      % Zonal grid length centered in X(ix),Y(iY)
      if ix == 1
         dx = abs(m_lldist([X(ix) X(ix+1)],[1 1]*Y(iy)))/2;
      elseif ix == nx 
         dx = abs(m_lldist([X(ix-1) X(ix)],[1 1]*Y(iy)))/2;
      else
         dx = abs(m_lldist([X(ix-1) X(ix)],[1 1]*Y(iy)))/2+abs(m_lldist([X(ix) X(ix+1)],[1 1]*Y(iy)))/2;
      end	
 
      % Meridional grid length centered in X(ix),Y(iY)
      if iy == 1
        dy = abs(m_lldist([1 1]*X(ix),[Y(iy) Y(iy+1)]))/2;
      elseif iy == ny
        dy = abs(m_lldist([1 1]*X(ix),[Y(iy-1) Y(iy)]))/2;
      else	
        dy = abs(m_lldist([1 1]*X(ix),[Y(iy-1) Y(iy)]))/2+abs(m_lldist([1 1]*X(ix),[Y(iy) Y(iy+1)]))/2;
      end

      % Surface element:
      DA = dx*dy.*ones(1,nz);
      
      % Volume element:
      DV(:,iy,ix) = DZ.*DA;
  end %for iy
end %for ix

                                                         gmaze_pv/test/test_intbet2outcrops.m                                                                0000644 0023526 0000144 00000002752 10506046003 017257  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % Test of the function intbet2outcrops
clear

% Theoritical fields:
eg = 2;

switch eg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
 case 1 % The more simple:
  % Axis:
  lon = [200:1/8:300]; nlon = length(lon);
  lat = [0:1/8:20];    nlat = length(lat);
    
  % chp goes linearly from 20 at 0N to 0 at 20N
  [a chp] = meshgrid(lon,-lat+lat(nlat)); clear a c
  [a chp] = meshgrid(lon,-lat+2); clear a c
  chp(14:16,:) = -1; % Make the integral proportional to the surface
    
  % Define limits:
  LIMITS(1) = -1 ; 
  LIMITS(2) = -1 ;
  LIMITS(3:4) = lat([14 16]) ;
  LIMITS(5:6) = lon([1 nlon]) ;
   
  % Expected integral:
  dx = m_lldist([200 300],[1 1]*1.75)./1000;
  dy = m_lldist([1 1],[1.625 1.875])./1000;
  Iexp = dx*dy/2; % Unit is km^2
  
  
 case 2
  % Axis:
  lon = [200:1/8:300]; nlon = length(lon);
  lat = [0:1:40];    nlat = length(lat);
  
  %
  [a chp]=meshgrid(lon,40-lat);
  
  % Define limits:
  LIMITS(1) =  9.5 ; 
  LIMITS(2) = 10.5 ;
  LIMITS(3:4) = lat([1 nlat]) ;
  LIMITS(5:6) = lon([1 nlon]) ;
   
  Iexp=4;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
end %switch


% Get integral:
[I Imat dI] = intbet2outcrops(chp,LIMITS,lat,lon);

disp('Computed:')
disp(num2str(I/1000^2))
disp('Approximatly expected:')
disp(num2str(Iexp))

%break
figure;iw=1;jw=2;
subplot(iw,jw,1);hold on
pcolor(chp);shading flat;canom;colorbar;axis tight
title('Tracer to integrate');

subplot(iw,jw,2);hold on
pcolor(double(Imat));shading flat;canom;colorbar;axis tight
title('Points selected for the integration');
                      gmaze_pv/test/test_surfbet2outcrops.m                                                               0000664 0023526 0000144 00000001610 10444073147 017450  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % Test of the function surfbet2outcrops
%

clear

% Theoritical fields:
eg = 1;

switch eg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
 case 1 % The more simple:
  % Axis:
  lon = [200:1/8:300]; nlon = length(lon);
  lat = [0:1/8:20];   nlat = length(lat);
    
  % chp goes linearly from 20 at 0N to 0 at 20N
  [a chp] = meshgrid(lon,-lat+lat(nlat)); clear a c
%  chp(:,1:400) = chp(:,1:400).*NaN;
  
  % Define limits:
  LIMITS(1) = 18 ; % Between 1.75N and 2N
  LIMITS(2) = 18.2 ;
  LIMITS(3:4) = lat([1 nlat]) ;
  LIMITS(5:6) = lon([1 nlon]) ;
   
  % Expected surface:
  dx = m_lldist([200 300],[1 1]*1.875)./1000;
  dy = m_lldist([1 1],[1.75 2])./1000;
  Sexp = dx*dy; % Unit is km^2
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
end %switch



% Get surface:
[S Smat dS] = surfbet2outcrops(chp,LIMITS,lat,lon);

disp('Computed:')
disp(num2str(S/1000^2))
disp('Approximatly expected:')
disp(num2str(Sexp))
                                                                                                                        gmaze_pv/test/test_volbet2iso.m                                                                     0000664 0023526 0000144 00000002073 10444073303 016203  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % Test of the function volbet2iso
%

clear

% Theoritical fields:
eg = 1;

switch eg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
 case 1 % The more simple:
  % Axis:
  lon = [200:1/8:300]; nlon = length(lon);
  lat = [0:1/8:20];   nlat = length(lat);
  dpt = [5:5:1000];    ndpt = length(dpt);
    
  % chp goes linearly from 10 at 30N to 0 at 40N
  % uniformely between the surface and the bottom:
  [a chp c] = meshgrid(lon,-lat+lat(nlat),dpt); clear a c
  chp = permute(chp,[3 1 2]);
  %chp(:,:,1:400) = chp(:,:,1:400).*NaN;
  
  % Define limits:
  LIMITS(1) = 18 ; % Between 1.75N and 2N
  LIMITS(2) = 18.2 ;
  LIMITS(3) = dpt(ndpt) ;
  LIMITS(4:5) = lat([1 nlat]) ;
  LIMITS(6:7) = lon([1 nlon]) ;
   
  % Expected volume: 
  dx = m_lldist([200 300],[1 1]*1.875)./1000;
  dy = m_lldist([1 1],[1.75 2])./1000;
  dz = dpt(ndpt)./1000;
  Vexp = dx*dy*dz; % Unit is km^3
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
end %switch



% Get volume:
[V Vmat dV] = volbet2iso(chp,LIMITS,dpt,lat,lon);

disp('Computed:')
disp(num2str(V/1000^3))
disp('Approximatly expected:')
disp(num2str(Vexp))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     gmaze_pv/visu/eg_view_Timeserie.m                                                                   0000644 0023526 0000144 00000023221 10511523746 016520  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% THIS IS NOT A FUNCTION !
%
% Plot time series of all variables in different ways
% Outputs recording possible
%

clear
global sla netcdf_domain
pv_checkpath

% Path and extension to find files:
pathname = strcat('netcdf-files',sla);
%pathname = strcat('netcdf-files-twice-daily',sla);
%pathname = strcat('netcdf-files-daily',sla);
ext      = 'nc';
netcdf_domain = 'western_north_atlantic'; 

% Date series:
ID    = datenum(2000,12,31,12,0,0); % Start date
ID    = datenum(2000,12,31,0,0,0); % Start date
ID    = datenum(2001,1,1,12,0,0); % Start date
ID    = datenum(2001,4,1,0,0,0); % Start date
%IDend = datenum(2001,2,26,12,0,0); % End date
IDend = datenum(2001,7,4,0,0,0); % End date

dt = datenum(0,0,1,0,0,0); % Time step between input: 1 day
%dt = datenum(0,0,2,0,0,0); % Time step between input: 2 days
%dt = datenum(0,0,7,0,0,0); % Time step between input: 1 week
%dt = datenum(0,0,0,12,0,0); % Time step between input: 12 hours
IDend = ID + 1*dt; % 
nt = (IDend-ID)/dt;

% Create TIME table:
for it = 1 : nt
  ID = ID + dt;
  snapshot = datestr(ID,'yyyymmddHHMM'); % For twice-daily data
%  snapshot = datestr(ID,'yyyymmdd'); % For daily data
  TIME(it,:) = snapshot;
end %for it


% Some settings
iso    = 25.25; % Which sigma-theta surface ?
getiso = 0;    % We do not compute the isoST by default
outimg = 'img_tmp'; % Output directory
%outimg = 'img_tmp2'; % Output directory
%outimg = 'img_tmp3'; % Output directory
prtimg = 0; % Do we record figures as jpg files ?

% Plot modules available:
sub = get_plotlist('eg_view_Timeserie','.');
disp('Available plots:')
sub = get_plotlistdef('eg_view_Timeserie','.');
disp('Set the variable <pl> in view_Timeserie.m with wanted plots')

% Selected plots list:
pl = [7]; %getiso=1;

% Verif plots:
disp(char(2));disp('You have choosed to plot:')
for i = 1 : length(pl)
  disp(strcat(num2str(pl(i)),' -> ', sub(pl(i)).description ) )
end
s = input(' Are you sure ([y]/n) ?','s');
if ~isempty(s) & s == 'n'
    return
end

% To find a specific date
%find(str2num(TIME)==200103300000),break

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Video loop:
for it = 1 : nt
  snapshot = TIME(it,:);
  %titf='.section_32N';if ~exist(strcat(outimg,sla,'PV.',snapshot,titf,'.jpg'),'file')
  
%%%%%%%%%%%%%%%%
% NETCDF files name:
filPV   = 'PV';
filST   = 'SIGMATHETA';
filT    = 'THETA';
filTx   = 'TAUX';
filTy   = 'TAUY';
filJFz  = 'JFz';
filJBz  = 'JBz';
filQnet = 'TFLUX';
filQEk  = 'QEk';
%filMLD  = 'KPPmld';
filMLD  = 'MLD';
filOx   = 'OMEGAX';
filOy   = 'OMEGAY';
filZET  = 'ZETA';
filEKL  = 'EKL';


% Load fields:
disp('load fields...')
% (I keep proper axis for each variables in case of one day they would be different)
         ferfile = strcat(pathname,sla,snapshot,sla,filPV,'.',netcdf_domain,'.',ext);
             ncQ = netcdf(ferfile,'nowrite');
[Qlon Qlat Qdpt] = coordfromnc(ncQ);
               Q = ncQ{4}(:,:,:); clear ncQ ferfile
      [nz ny nx] = size(Q);
      %Qdpt = -Qdpt;

                  ferfile = strcat(pathname,sla,snapshot,sla,filZET,'.',netcdf_domain,'.',ext);
                    ncZET = netcdf(ferfile,'nowrite');
[ZETAlon ZETAlat ZETAdpt] = coordfromnc(ncZET);
                     ZETA = ncZET{4}(:,:,:); clear ncZET ferfile
  % Move ZETA on the same grid as Q:
  ZETA = ( ZETA(:,:,2:nx-1) + ZETA(:,:,1:nx-2) )./2;
  ZETA = ( ZETA(:,2:ny-1,:) + ZETA(:,1:ny-2,:) )./2;
  ZETAlon = ( ZETAlon(2:nx-1) + ZETAlon(1:nx-2) )./2;	
  ZETAlat = ( ZETAlat(2:ny-1) + ZETAlat(1:ny-2) )./2;

            ferfile = strcat(pathname,sla,snapshot,sla,filOx,'.',netcdf_domain,'.',ext);
               ncOX = netcdf(ferfile,'nowrite');
[OXlon OXlat OXdpt] = coordfromnc(ncOX);
                 OX = ncOX{4}(:,:,:); clear ncOX ferfile
  % Move OMEGAx on the same grid as Q:
  OX = ( OX(:,2:ny-1,:) + OX(:,1:ny-2,:) )./2;
  OX = ( OX(2:nz-1,:,:) + OX(1:nz-2,:,:) )./2;
  OXlat = ( OXlat(2:ny-1) + OXlat(1:ny-2) )./2;
  OXdpt = ( OXdpt(2:nz-1) + OXdpt(1:nz-2) )./2;

            ferfile = strcat(pathname,sla,snapshot,sla,filOy,'.',netcdf_domain,'.',ext);
               ncOY = netcdf(ferfile,'nowrite');
[OYlon OYlat OYdpt] = coordfromnc(ncOY);
                 OY = ncOY{4}(:,:,:); clear ncOY ferfile
  % Move OMEGAy on the same grid as Q:
  OY = ( OY(2:nz-1,:,:) + OY(1:nz-2,:,:) )./2;
  OY = ( OY(:,:,2:nx-1) + OY(:,:,1:nx-2) )./2;
  OYdpt = ( OYdpt(2:nz-1) + OYdpt(1:nz-2) )./2;
  OYlon = ( OYlon(2:nx-1) + OYlon(1:nx-2) )./2;
  
  
            ferfile = strcat(pathname,sla,snapshot,sla,filST,'.',netcdf_domain,'.',ext);
               ncST = netcdf(ferfile,'nowrite');
[STlon STlat STdpt] = coordfromnc(ncST);
                 ST = ncST{4}(:,:,:); clear ncST ferfile

         ferfile = strcat(pathname,sla,snapshot,sla,filT,'.',netcdf_domain,'.',ext);
             ncT = netcdf(ferfile,'nowrite');
[Tlon Tlat Tdpt] = coordfromnc(ncT);
               T = ncT{4}(:,:,:); clear ncT ferfile
	      
              ferfile = strcat(pathname,sla,snapshot,sla,filTx,'.',netcdf_domain,'.',ext);
                 ncTx = netcdf(ferfile,'nowrite');
  [Txlon Txlat Txdpt] = coordfromnc(ncTx);
                   Tx = ncTx{4}(1,:,:); clear ncTx ferfile
              ferfile = strcat(pathname,sla,snapshot,sla,filTy,'.',netcdf_domain,'.',ext);
                 ncTy = netcdf(ferfile,'nowrite');
  [Tylon Tylat Tydpt] = coordfromnc(ncTy);
                   Ty = ncTy{4}(1,:,:); clear ncTy ferfile
  
                 ferfile = strcat(pathname,sla,snapshot,sla,filJFz,'.',netcdf_domain,'.',ext);
                   ncJFz = netcdf(ferfile,'nowrite');
  [JFzlon JFzlat JFzdpt] = coordfromnc(ncJFz);
                     JFz = ncJFz{4}(1,:,:);
  
                 ferfile = strcat(pathname,sla,snapshot,sla,filJBz,'.',netcdf_domain,'.',ext);
                   ncJBz = netcdf(ferfile,'nowrite');
  [JBzlon JBzlat JBzdpt] = coordfromnc(ncJBz);
                     JBz = ncJBz{4}(1,:,:);
  
                  ferfile = strcat(pathname,sla,snapshot,sla,filQnet,'.',netcdf_domain,'.',ext);
                   ncQnet = netcdf(ferfile,'nowrite');
[Qnetlon Qnetlat Qnetdpt] = coordfromnc(ncQnet);
                     Qnet = ncQnet{4}(1,:,:);
% $$$ 
% $$$                ferfile = strcat(pathname,sla,snapshot,sla,filQEk,'.',netcdf_domain,'.',ext);
% $$$                  ncQEk = netcdf(ferfile,'nowrite');
% $$$ [QEklon QEklat QEkdpt] = coordfromnc(ncQEk);
% $$$                    QEk = ncQEk{4}(1,:,:);
% $$$ 
                 ferfile = strcat(pathname,sla,snapshot,sla,filMLD,'.',netcdf_domain,'.',ext);
                   ncMLD = netcdf(ferfile,'nowrite');
  [MLDlon MLDlat MLDdpt] = coordfromnc(ncMLD);
                     MLD = ncMLD{4}(1,:,:);
  
                 ferfile = strcat(pathname,sla,snapshot,sla,filEKL,'.',netcdf_domain,'.',ext);
                   ncEKL = netcdf(ferfile,'nowrite');
  [EKLlon EKLlat EKLdpt] = coordfromnc(ncEKL);
                     EKL = ncEKL{4}(1,:,:);

	       
%%%%%%%%%%%%%%%%
% Q is defined on the same grid of ST but troncated by extrem 2 points, then here
% make all fields defined with same limits...
% In case of missing points, we add NaN.
disp('Reshape them')
ST    = squeeze(ST(2:nz+1,2:ny+1,2:nx+1));
STdpt = STdpt(2:nz+1);
STlon = STlon(2:nx+1);
STlat = STlat(2:ny+1);
T    = squeeze(T(2:nz+1,2:ny+1,2:nx+1));
Tdpt = Tdpt(2:nz+1);
Tlon = Tlon(2:nx+1);
Tlat = Tlat(2:ny+1);
JBz    = squeeze(JBz(2:ny+1,2:nx+1));
JBzlon = JBzlon(2:nx+1);
JBzlat = JBzlat(2:ny+1);
Qnet    = squeeze(Qnet(2:ny+1,2:nx+1));
Qnetlon = Qnetlon(2:nx+1);
Qnetlat = Qnetlat(2:ny+1);
MLD    = squeeze(MLD(2:ny+1,2:nx+1));
MLDlon = MLDlon(2:nx+1);
MLDlat = MLDlat(2:ny+1);
EKL    = squeeze(EKL(2:ny+1,2:nx+1));
EKLlon = EKLlon(2:nx+1);
EKLlat = EKLlat(2:ny+1);
ZETA = squeeze(ZETA(2:nz+1,:,:));
ZETA = cat(2,ZETA,ones(size(ZETA,1),1,size(ZETA,3)).*NaN);
ZETA = cat(2,ones(size(ZETA,1),1,size(ZETA,3)).*NaN,ZETA);
ZETA = cat(3,ZETA,ones(size(ZETA,1),size(ZETA,2),1).*NaN);
ZETA = cat(3,ones(size(ZETA,1),size(ZETA,2),1).*NaN,ZETA);
ZETAdpt = ZETAdpt(2:nz+1);
ZETAlon = STlon;
ZETAlat = STlat;
OX = squeeze(OX(:,:,2:nx+1));
OX = cat(1,OX,ones(1,size(OX,2),size(OX,3)).*NaN);
OX = cat(1,ones(1,size(OX,2),size(OX,3)).*NaN,OX);
OX = cat(2,OX,ones(size(OX,1),1,size(OX,3)).*NaN);
OX = cat(2,ones(size(OX,1),1,size(OX,3)).*NaN,OX);
OXlon = STlon;
OXlat = STlat;
OXdpt = STdpt;
OY = squeeze(OY(:,2:ny+1,:));
OY = cat(1,OY,ones(1,size(OY,2),size(OY,3)).*NaN);
OY = cat(1,ones(1,size(OY,2),size(OY,3)).*NaN,OY);
OY = cat(3,OY,ones(size(OY,1),size(OY,2),1).*NaN);
OY = cat(3,ones(size(OY,1),size(OY,2),1).*NaN,OY);
OYlon = STlon;
OYlat = STlat;
OYdpt = STdpt;


% Planetary vorticity:
  f = 2*(2*pi/86400)*sin(ZETAlat*pi/180);
  [a f c]=meshgrid(ZETAlon,f,ZETAdpt); clear a c
  f = permute(f,[3 1 2]);
  
% Apply mask:
MASK = ones(size(ST,1),size(ST,2),size(ST,3)); 
MASK(find(isnan(ST))) = NaN;
T = T.*MASK;
Qnet = Qnet.*squeeze(MASK(1,:,:));

  
% Grid:
global domain subdomain1 subdomain2 subdomain3
grid_setup
subdomain = subdomain1;


%%%%%%%%%%%%%%%%
% Here we determine the isosurface and its depth:
if getiso
  disp('Get iso-ST')
[Iiso mask] = subfct_getisoS(ST,iso);
Diso = ones(size(Iiso)).*NaN;
Qiso = ones(size(Iiso)).*NaN;
for ix = 1 : size(ST,3)
  for iy = 1 : size(ST,2) 
    if ~isnan(Iiso(iy,ix)) & ~isnan( Q(Iiso(iy,ix),iy,ix) )
       Diso(iy,ix) = STdpt(Iiso(iy,ix));
       Qiso(iy,ix) =     Q(Iiso(iy,ix),iy,ix);
    end %if
end, end %for iy, ix
end %if



%%%%%%%%%%%%%%%%
% "Normalise" the PV:
fO  = 2*(2*pi/86400)*sin(32*pi/180);
dST = 27.6-25.4;
H   = -1000;
RHOo = 1000;
Qref = -fO/RHOo*dST/H;
if getiso, QisoN = Qiso./Qref; end


%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
% Plots:
disp('Plots ...')


for i = 1 : length(pl)
  disp(strcat('Plotting module:',sub(pl(i)).name))
  eval(sub(pl(i)).name(1:end-2),'disp(''Oups scratch...'');return');
end


%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%

  %else,disp(strcat('Skip:',snapshot));end

fclose('all');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
end %for it  
                                                                                                                                                                                                                                                                                                                                                                               gmaze_pv/visu/eg_view_Timeserie_pl1.m                                                               0000644 0023526 0000144 00000034020 10511523556 017272  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %DEF 1 var per figure

% Map projection:
m_proj('mercator','long',subdomain.limlon,'lat',subdomain.limlat);
%m_proj('mercator','long',subdomain2.limlon,'lat',subdomain2.limlat);
%m_proj('mercator','long',subdomain.limlon,'lat',[25 40]);
%m_proj('mercator','long',[subdomain.limlon(1) 360-24],'lat',[25 50]);

% Which variables to plot:
wvar = [21 10 7 22];
wvar = [12];

for ip = 1 : length(wvar)
  
  figur(10+ip);clf;drawnow;hold on;iw=1;jw=1;

% Variables loop:
  % Default:
  CBAR = 'v'; % Colorbar orientation
  Tcontour = [17 19]; Tcolor = [0 0 0]; % Theta contours
  Hcontour = -[0:200:600]; Hcolor = [0 0 0]; % MLD contours
  unit = ''; % Default unit
  load mapanom2 ; N = 256; c = [0 0]; cmap = jet; % Colormaping
  uselogmap = 1; % Use the log colormap
  showT = 1; % Iso-Theta contours
  showW = 0; % Windstress arrows
  showH = 0; colorW = 'w'; % Mixed Layer Depth
  showE = 0; colorE = 'w'; % Ekman Layer Depth
  showCLIM = 1; % Show CLIMODE region box
  showQnet = 0 ; Qnetcontour = [-1000:100:1000]; % Show the Net heat flux
  CONT  = 0; % Contours instead of pcolor
  CONTshlab = 0; % Show label for contours plot
  CONTc  = 0; % Highlighted contours instead of pcolor
  CONTcshlab = 0; % Show label for contours plot
  colorCOAST = [0 0 0]; % Land color
  SHADE = 'flat'; % shading option
  
  %if it==1, mini; end 
switch wvar(ip)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 1
 case 1
  C     = Diso;
  Clon  = Qlon; Clat = Qlat;
  tit   = strcat('Depth of \sigma_\theta=',num2str(iso),'kg.m^{-3}');
  showW = 0; % Windstress
  cx    = [-600 0];
  unit  = 'm';
  titf  = 'Diso';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 11
 case 11
  C     = Qiso;
  %C(isnan(C)) = 10;
  Clon  = Qlon; Clat = Qlat;
  tit   = strcat('Full potential vorticity field on iso-\sigma=',num2str(iso));
  colorCOAST = [1 1 1]*.5; % Land color
  showW = 0; % Windstress
  showH = 0;
  showCLIM = 1;
  showT = 1; 
  Tcontour = [22 22];
  N     = 256;
  c     = [1 5];
  cx    = [-(1+2*c(1)) 1+2*c(2)]*5e-10; cmap = mapanom; %cmap = jet;
  unit  = '1/m/s';
  titf  = strcat('PViso_',num2str(iso));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 12
 case 12
  % First iso-ST have been computed in view_Timeserie
  % Here is the 2nd one (supposed to be deeper than the 1st one)
  iso2 = 25.35;
  disp('Get 2nd iso-ST')
  [Iiso mask] = subfct_getisoS(ST,iso2);
  Diso1 = Diso;
  Diso2 = ones(size(Iiso)).*NaN;
  Qiso2 = ones(size(Iiso)).*NaN;
  for ix = 1 : size(ST,3)
    for iy = 1 : size(ST,2) 
      if ~isnan(Iiso(iy,ix)) & ~isnan( Q(Iiso(iy,ix),iy,ix) )
        Diso2(iy,ix) = STdpt(Iiso(iy,ix));
        Qiso2(iy,ix) =     Q(Iiso(iy,ix),iy,ix);
      end %if
  end, end %for iy, ix
  Diso1(isnan(squeeze(MASK(1,:,:)))) = NaN;
  Diso2(isnan(squeeze(MASK(1,:,:)))) = NaN;
  for ix = 1 : size(ST,3)
    for iy = 1 : size(ST,2) 
      if isnan(Diso1(iy,ix)) & isnan(Diso2(iy,ix))
	Hbiso(iy,ix) = -Inf;
      elseif isnan(Diso1(iy,ix)) & ~isnan(Diso2(iy,ix))
	Hbiso(iy,ix) = Inf;
      elseif ~isnan(Diso1(iy,ix)) & ~isnan(Diso2(iy,ix))
	Hbiso(iy,ix) = Diso1(iy,ix) - Diso2(iy,ix);
      end
  end, end %for iy, ix
  Hbiso = Hbiso.*squeeze(MASK(1,:,:));  
  %figur(1);pcolor(Diso1);shading flat;colorbar
  %figur(2);pcolor(Diso2);shading flat;colorbar
  %figur(3);pcolor(Hbiso);shading flat;colorbar

  C     = Hbiso;
  %C(isnan(C)) = NaN;
  Clon  = STlon; Clat = STlat;
  tit   = strvcat(strcat('Height between iso-\sigma=',num2str(iso),...
			 ' and: iso-\sigma=',num2str(iso2)),...
		  strcat('(White areas are outcrops for both iso-\sigma and red areas only for: ',...
			 num2str(iso),')'));
  colorCOAST = [1 1 0]*.8; % Land color
  showW = 1; colorW = 'k';  % Windstress
  showH = 0; % Mixed layer depth
  showCLIM = 1; % CLIMODE
  showT = 0;  Tcontour = [21 23]; % THETA
  CONTc = 0; CONTcv = [0:0]; CONTcshlab = 1; 
  showQnet = 1; Qnetcontour=[[-1000:200:-400] [400:200:1000]];
  cx    = [0 300];   uselogmap = 0;
  cmap  = [[1 1 1]; jet ; [1 0 0]]; 
  unit  = 'm';
  titf  = strcat('Hbiso_',num2str(iso),'_',num2str(iso2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 2
 case 2
  C     = QisoN; % C = Qiso;
  Clon  = Qlon; Clat = Qlat;
  tit   = strcat(snapshot,'/ Potential vorticity field: q = (-f/\rho . d\sigma_\theta/dz) / q_{ref}');
  %tit   = strcat(snapshot,'/ Potential vorticity field: q = - f . d\sigma_\theta/dz / \rho');
  showW = 0; % Windstress
  cx    = [0 1]*10;
  unit  = char(1);
  titf  = 'PVisoN';
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 21
 case 21
  C     = squeeze(Q(1,:,:));
  Clon  = Qlon; Clat = Qlat;
  tit   = strcat('Surface potential vorticity field');
  showW = 0; % Windstress
  showH = 0;
  showCLIM = 1;
  N     = 256;
  c     = [1 12];  cx = [-(1+2*c(1)) 1+2*c(2)]*1e-14;  cmap = mapanom; % ecco2_bin1
  c     = [1 12];  cx = [-(1+2*c(1)) 1+2*c(2)]*1e-11;  cmap = mapanom; % ecco2_bin2
  unit  = '1/m/s';
  titf  = 'PV.Lsurface';
  %SHADE = 'interp';
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 22
 case 22
  C     = squeeze(Q(11,:,:));
  Clon  = Qlon; Clat = Qlat;
  tit   = strcat('Full potential vorticity field (-115m)');
  showW = 0; % Windstress
  N     = 32;
  c     = [1 12];
  c     = [1 12];  cx = [-(1+2*c(1)) 1+2*c(2)]*1e-14;  cmap = mapanom; % ecco2_bin1
  c     = [1 12];  cx = [-(1+2*c(1)) 1+2*c(2)]*1e-11;  cmap = mapanom; % ecco2_bin2
  unit  = '1/m/s';
  titf  = 'PV.L115';
  colorCOAST = [1 1 1]*.5;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 3
 case 3
  C     = JFz;
  Clon  = JFzlon; Clat = JFzlat;
  %tit   = strcat(snapshot,'/ Mechanical PV flux J^F_z and windstress');
  tit   = strvcat(['Mechanical PV flux J^F_z (positive upward), Ekman layer depth (green contours' ...
		   ' m)'],'and windstress (black arrows)');
  %Tcolor = [0 0 0];
  showW = 1; % Windstress
  colorW = 'k';
  showE = 1; 
  Econtour = [10 20:20:200]; 
  N     = 256;
  c     = [1 1];
  cx    = [-(1+2*c(1)) 1+2*c(2)]*1e-11; cmap = mapanom; %cmap = jet;
  %cx    = [-1 1]*10^(-11);
  unit  = 'kg/m^3/s^2';
  titf  = 'JFz';
  showCLIM = 1;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 4
  
 case 4
  C     = JBz;
  Clon  = JBzlon; Clat = JBzlat;
  tit   = strcat(snapshot,'/ Diabatic PV flux J^B_z and windstress');
  showW = 1; % Windstress
  cx    = [-1 1]*10^(-11);
  unit  = 'kg/m^3/s^2';
  titf  = 'JBz';
  
 case 5
  C     = Qnet;
  Clon  = Qnetlon; Clat = Qnetlat;
  tit   = ['Net surface heat flux Q_{net} (positive downward), mixed layer depth (green contours,' ...
	   ' m) and windstress (black arrows)'];
  tit   = ['Net surface heat flux Q_{net} (positive downward), and windstress (black arrows)'];
  showH = 0;
  Hcontour = -[100 200:200:600];
  showT = 0;
  showW = 1; colorW = 'k';
  N     = 256;
  c     = [1 1]; cx    = [-(1+2*c(1)) 1+2*c(2)]*200; cmap = mapanom;
  %cx    = [-1 1]*500;
  cmap  = mapanom;  
  unit  = 'W/m^2';
  titf  = 'Qnet';
  showCLIM = 1;
  colorCOAST = [0 0 0];
  
 case 6
  C     = JFz./JBz;
  Clon  = JFzlon; Clat = JFzlat;
  tit   = strcat(snapshot,'/ Ratio: J^F_z/J^B_z');
  cx    = [-1 1]*5;
  unit  = char(1);
  titf  = 'JFz_vs_JBz';
  
 case 7
  C     = squeeze(ST(1,:,:));
  C(isnan(C)) = 0;
  Clon  = STlon; Clat = STlat;
  tit   = strcat('Surface Potential density \sigma_\theta ');
  showT = 0; % 
  cmap  = flipud(hot);
  CONT  = 1;  CONTv = [20:.2:30];  CONTshlab = 0;
  CONTc  = 1; CONTcv = [20:1:30];  CONTcshlab = 1;
  cx    = [23 28];
  unit  = 'kg/m^3';
  titf  = 'SIGMATHETA';
  colorCOAST = [1 1 1]*.5;
  
 case 8
  C     = squeeze(ZETA(1,:,:));
  Clon  = ZETAlon; Clat = ZETAlat;
  tit   = strcat('Surface relative vorticity');
  showW = 0; % Windstress
  showH = 0;
  showCLIM = 1;
  N     = 256;
  c     = [0 0];
  cx    = [-(1+2*c(1)) 1+2*c(2)]*6e-5; cmap = mapanom;
  unit  = '1/s';
  titf  = 'ZETA';
  
 case 9
  C     = abs(squeeze(ZETA(1,:,:))./squeeze(f(1,:,:)));
  Clon  = ZETAlon; Clat = ZETAlat;
  tit   = strcat('Absolute ratio between relative and planetary vorticity');
  showW = 0; % Windstress
  showH = 0;
  showCLIM = 1;
  N     = 256;
  c     = [0 1];
  cx    = [0 1+3*c(2)];
  cmap  = flipud(hot); cmap = mapanom;
  unit  = '';
  titf  = 'ZETA_vs_f';
  
 case 10
  C     = squeeze(T(1,:,:));
  Clon  = Tlon; Clat = Tlat;
  tit   = strcat('Surface Potential temperature \theta ');
  showT = 0; % 
  N = 256; c = [0 0];
  cmap  = flipud(hot); cmap = jet;
  CONT  = 0;  CONTv = [0:1:40];  CONTshlab = 0;
  CONTc = 1; CONTcv = [0:1:40]; CONTcshlab = 1; 
  cx    = [0 30];
  unit  = '^oK';
  titf  = 'THETA';
  colorCOAST = [1 1 1]*.5;


end %switch what to plot

% Draw variable:
sp=subplot(iw,jw,1);hold on
if CONT ~= 1
  m_pcolor(Clon,Clat,C);
  shading(SHADE);
  if uselogmap
     colormap(logcolormap(N,c(1),c(2),cmap));
  else
     colormap(cmap);
  end
  
  if wvar(ip) == 10
    if CONTc
     clear cs h csh
     EDW = [21:23];
     [cs,h] = m_contour(Clon,Clat,C,CONTcv,'k');
     csh = clabel(cs,h,'fontsize',8,'labelspacing',800); 
     set(csh,'visible','on');
      for ih = 1 : length(h)
       if find(EDW == get(h(ih),'Userdata'))
 	set(h(ih),'linewidth',1.5)
       end %if
       if find(EDW(2) == get(h(ih),'Userdata'))
 	set(h(ih),'linestyle','--')
       end %if
      end %for 
      for icsh = 1 : length(csh)
	if find(EDW == get(csh(icsh),'userdata') )
	  set(csh(icsh),'visible','on');
	end %if
      end %for
     end %if CONTc
  end % if ST
  
else 
  clear cs h csh
  [cs,h] = m_contourf(Clon,Clat,C,CONTv);
  if uselogmap
    colormap(mycolormap(logcolormap(N,c(1),c(2),cmap),length(CONTv)));
  else
    colormap(mycolormap(cmap,length(CONTv)));
  end
  csh = clabel(cs,h,'fontsize',8,'labelspacing',800); 
  set(csh,'visible','off');
  if CONTshlab
    set(csh,'visible','on');
  end
  if CONTc
    for ih = 1 : length(h)
      if find(CONTcv == get(h(ih),'CData'))
	set(h(ih),'linewidth',1.5)	
      end
    end
    if CONTcshlab
    for ih = 1 : length(csh)
      if find(CONTcv == str2num( get(csh(ih),'string') ) )
	set(csh(ih),'visible','on','color','k','fontsize',8);
	set(csh(ih),'fontweight','bold','margin',1e-3);
      end
    end
    end
  end
end
caxis(cx);
ccol(ip) = colorbar(CBAR,'fontsize',10);
ctitle(ccol(ip),unit);
title(tit);
m_coast('patch',colorCOAST);
m_grid('xtick',360-[20:5:80],'ytick',[20:2:50]);
set(gcf,'name',titf);

if wvar == 5 % Qnet (Positions depend on map limits !)
  yy=get(ccol,'ylabel');
  set(yy,'string','Cooling                                              Warming');
  set(yy,'fontweight','bold');
end %if

if showT
  clear cs h
  [cs,h] = m_contour(Tlon,Tlat,squeeze(T(1,:,:)),Tcontour);
  clabel(cs,h,'fontsize',8,'color',[0 0 0],'labelspacing',200);
  for ih=1:length(h)
    set(h(ih),'edgecolor',Tcolor,'linewidth',1.2);
  end
end %if show THETA contours

if showQnet
  clear cs h
  CQnet = Qnet;
  if wvar(ip) == 12
    %CQnet(isnan(C)) = NaN;
  end
  [cs,h] = m_contour(Qnetlon,Qnetlat,CQnet,Qnetcontour);
  Qnetmap = mycolormap(mapanom,length(Qnetcontour)); 
  if ~isempty(cs)
    clabel(cs,h,'fontsize',8,'color',[0 0 0],'labelspacing',200);
    for ih=1:length(h)
      val = get(h(ih),'userdata');
      set(h(ih),'edgecolor',Qnetmap( find(Qnetcontour == val) ,:),'linewidth',1);
    end
  end
end %if show Qnet contours

if showW
      dx = 10*diff(Txlon(1:2)); dy = 8*diff(Txlat(1:2));
      dx = 20*diff(Txlon(1:2)); dy = 10*diff(Txlat(1:2));
      lo = [Txlon(1):dx:Txlon(length(Txlon))];
      la = [Txlat(1):dy:Txlat(length(Txlat))];
      [lo la] = meshgrid(lo,la);
      Txn = interp2(Txlat,Txlon,Tx',la,lo);
      Tyn = interp2(Txlat,Txlon,Ty',la,lo);
      s = 2;
      m_quiver(lo,la,Txn,Tyn,s,colorW,'linewidth',1.25);
%      m_quiver(lo,la,-(1+sin(la*pi/180)).*Txn,(1+sin(la*pi/180)).*Tyn,s,'w');
      m_quiver(360-82,37,1,0,s,'w','linewidth',1.25);
        m_text(360-82,38,'1 N/m^2','color','w');
end %if show windstress

if showH
  clear cs h
  %[cs,h] = m_contour(MLDlon,MLDlat,MLD,Hcontour);
  cm = flipud(mycolormap(jet,length(Hcontour)));
  cm = mycolormap([linspace(0,0,20); linspace(1,.5,20) ;linspace(0,0,20)]',length(Hcontour));
  cm = [0 1 0 ; 0 .6 0 ; 0 .2 0 ; 0 0 0];
  for ii = 1 : length(Hcontour) 
    [cs,h] = m_contour(MLDlon,MLDlat,MLD,[1 1]*Hcontour(ii)); 
    if ~isempty(cs)
%    clabel(cs,h,'fontsize',8,'color',[0 0 0],'labelspacing',300);
    clabel(cs,h,'fontsize',8,'color',cm(ii,:),'labelspacing',600,'fontweight','bold');
    for ih=1:length(h)
%      set(h(ih),'edgecolor',Hcolor,'linewidth',1);
      set(h(ih),'edgecolor',cm(ii,:),'linewidth',1.2);
    end
    end
  end
end %if show Mixed Layer depth

if showE
  clear cs h
  %[cs,h] = m_contour(EKLlon,EKLlat,EKL,Econtour);
  %cm = flipud(mycolormap(jet,length(Econtour)));
  n = length(Econtour);
  cm = flipud([linspace(0,0,n); linspace(1,0,n) ;linspace(0,0,n)]');
  %cm = [0 1 0 ; 0 .6 0 ; 0 .2 0 ; 0 0 0];
  for ii = 1 : length(Econtour) 
    [cs,h] = m_contour(EKLlon,EKLlat,EKL,[1 1]*Econtour(ii)); 
    if ~isempty(cs)
%    clabel(cs,h,'fontsize',8,'color',[0 0 0],'labelspacing',300);
    cl=clabel(cs,h,'fontsize',8,'color',cm(ii,:),'labelspacing',600,'fontweight','bold');
    for ih = 1 : length(h)
%      set(h(ih),'edgecolor',Ecolor,'linewidth',1);
      set(h(ih),'edgecolor',cm(ii,:),'linewidth',1.2);
    end
    end
  end
end %if show Ekman Layer depth

if showCLIM
  m_line(360-[71 62 62 71 71],[36 36 40.5 40.5 36],'color','r','linewidth',1.5)
end

  
if 1 % Show the date in big in the upper left corner
  spp=subplot('position',[0 .95 .25 .05]);
  p=patch([0 1 1 0],[0 0 1 1],'w');
  set(spp,'ytick',[],'xtick',[]);
  set(spp,'box','off');
  dat = num2str(TIME(it,:));
  dat = strcat(dat(1:4),'/',dat(5:6),'/',dat(7:8),':',dat(9:10),'H',dat(11:12));
  text(0.1,.5,dat,'fontsize',16,...
       'fontweight','bold','color','r','verticalalign','middle');
end  

%%%%%%%%%%%%%%%%
drawnow
set(gcf,'position',[4 48 888 430]);
%videotimeline(num2str(zeros(size(TIME,1),1)),it,'b')
set(gcf,'color','white') 
set(findobj('tag','m_grid_color'),'facecolor','none')
if prtimg
set(gcf,'paperposition',[0.6 6.5 25 14]);
%print(gcf,'-djpeg100',strcat(outimg,sla,titf,'.',snapshot,'.jpg'));
exportj(gcf,0,strcat(outimg,sla,titf,'.',snapshot));
end %if


end %for ip

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                gmaze_pv/visu/eg_view_Timeserie_pl2.m                                                               0000644 0023526 0000144 00000012074 10511523556 017300  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %DEF All components of the relative vorticity

% Map projection:
m_proj('mercator','long',subdomain.limlon,'lat',subdomain.limlat);
%m_proj('mercator','long',subdomain2.limlon,'lat',subdomain2.limlat);
%m_proj('mercator','long',subdomain.limlon,'lat',[25 40]);
%m_proj('mercator','long',[subdomain.limlon(1) 360-24],'lat',[25 50]);

% Which variables to plot:
wvar = [1:3];
iz = 2; % Surface
%iz = 6; % Core of the Gulf Stream
%iz = 22; % Under the Gulf Stream

figure(12);clf;hold on;iw=1;jw=length(wvar);
  
for ip = 1 : length(wvar)

% Variables loop:
  % Default:
  CBAR = 'h'; % Colorbar orientation
  Tcontour = [17 19]; Tcolor = [0 0 0]; % Theta contours
  Hcontour = -[0:200:600]; Hcolor = [0 0 0]; % MLD contours
  unit = ''; % Default unit
  load mapanom2 ; N = 256; c = [0 0]; cmap = jet; % Colormaping
  showT = 1; % Iso-Theta contours
  showW = 0; % Windstress arrows
  showH = 0; colorW = 'w'; % Mixed Layer Depth
  showCLIM = 0; % Show CLIMODE region box
  CONT  = 0; % Contours instead of pcolor
  CONTshlab = 0; % Show label for contours plot
  colorCOAST = [0 0 0]; % Land color
  SHADE = 'flat'; % shading option
  
  N     = 32;
  c     = [12 30];
  cx    = [-(1+2*c(1)) 1+2*c(2)]*6e-5; cmap = mapanom;
  titf  = 'OMEGA';
  
switch wvar(ip)
 case 1
  C     = -squeeze(OX(iz,:,:));
  Clon  = OXlon; Clat = OXlat;
  tit   = strcat('\omega_x = - \partial v / \partial z');
  showW = 0; % Windstress
  showH = 0;
  showCLIM = 1;
  unit  = '1/s';
 case 2
  C     = -squeeze(OY(iz,:,:));
  Clon  = OYlon; Clat = OYlat;
  tit   = strcat('\omega_y =  \partial u / \partial z');
  showW = 0; % Windstress
  showH = 0;
  showCLIM = 1;
  %N     = 256;
  %c     = [10 10];
  %cx    = [-(1+2*c(1)) 1+2*c(2)]*6e-5; cmap = mapanom;
  unit  = '1/s';
 case 3
  C     = squeeze(ZETA(iz,:,:));
  Clon  = ZETAlon; Clat = ZETAlat;
  tit   = strcat('\zeta = \partial v / \partial x - \partial u / \partial y');
  showW = 0; % Windstress
  showH = 0;
  showCLIM = 1;
  %N     = 256;
  %c     = [10 10];
  %cx    = [-(1+2*c(1)) 1+2*c(2)]*6e-5; cmap = mapanom;
  unit  = '1/s';
end %switch what to plot


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw variable:
sp=subplot(iw,jw,ip);hold on
if CONT ~= 1
  m_pcolor(Clon,Clat,C);
  shading(SHADE);
  colormap(logcolormap(N,c(1),c(2),cmap));
else 
  [cs,h] = m_contourf(Clon,Clat,C,CONTv);
  colormap(mycolormap(logcolormap(N,c(1),c(2),cmap),length(CONTv)));
  if CONTshlab
    clabel(cs,h,'labelspacing',200,'fontsize',8)
  end
end
caxis(cx);
if ip == 2
  ccol = colorbar(CBAR,'fontsize',10);
  ctitle(ccol,unit);
  posiC = get(ccol,'position');
  set(ccol,'position',[.2 posiC(2) 1-2*.2 .02]);
end
title(tit);
m_coast('patch',colorCOAST);
m_grid('xtick',360-[20:5:80],'ytick',[20:2:50]);
set(gcf,'name',titf);


if showT
  [cs,h] = m_contour(Tlon,Tlat,squeeze(T(1,:,:)),Tcontour);
  clabel(cs,h,'fontsize',8,'color',[0 0 0],'labelspacing',200);
  for ih=1:length(h)
    set(h(ih),'edgecolor',Tcolor,'linewidth',1);
  end
end %if show THETA contours

if showW
      dx = 10*diff(Txlon(1:2)); dy = 8*diff(Txlat(1:2));
      dx = 20*diff(Txlon(1:2)); dy = 10*diff(Txlat(1:2));
      lo = [Txlon(1):dx:Txlon(length(Txlon))];
      la = [Txlat(1):dy:Txlat(length(Txlat))];
      [lo la] = meshgrid(lo,la);
      Txn = interp2(Txlat,Txlon,Tx',la,lo);
      Tyn = interp2(Txlat,Txlon,Ty',la,lo);
      s = 2;
      m_quiver(lo,la,Txn,Tyn,s,colorW,'linewidth',1.25);
%      m_quiver(lo,la,-(1+sin(la*pi/180)).*Txn,(1+sin(la*pi/180)).*Tyn,s,'w');
      m_quiver(360-84,47,1,0,s,'w','linewidth',1.25);
        m_text(360-84,48,'1 N/m^2','color','w');
end %if show windstress

if showH
  %[cs,h] = m_contour(MLDlon,MLDlat,MLD,Hcontour);
  cm = flipud(mycolormap(jet,length(Hcontour)));
  cm = mycolormap([linspace(0,0,20); linspace(1,.5,20) ;linspace(0,0,20)]',length(Hcontour));
  cm = [0 1 0 ; 0 .6 0 ; 0 .2 0 ; 0 0 0];
  for ii = 1 : length(Hcontour) 
    [cs,h] = m_contour(MLDlon,MLDlat,MLD,[1 1]*Hcontour(ii)); 
    if ~isempty(cs)
%    clabel(cs,h,'fontsize',8,'color',[0 0 0],'labelspacing',300);
    clabel(cs,h,'fontsize',8,'color',cm(ii,:),'labelspacing',600,'fontweight','bold');
    for ih=1:length(h)
%      set(h(ih),'edgecolor',Hcolor,'linewidth',1);
      set(h(ih),'edgecolor',cm(ii,:),'linewidth',1.2);
    end
    end
  end
end %if show Mixed Layer depth

if showCLIM
  m_line(360-[71 62 62 71 71],[36 36 40.5 40.5 36],'color','r','linewidth',1.5)
end

%suptitle(strcat('Relative vorticity component at depth:',num2str(OYdpt(iz)),'m'));

  
end %for ip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 1 % Show the date in big in the upper left corner
  spp=subplot('position',[0 .95 .25 .05]);
  p=patch([0 1 1 0],[0 0 1 1],'w');
  set(spp,'ytick',[],'xtick',[]);
  set(spp,'box','off');
  text(0.1,.5,num2str(TIME(it,:)),'fontsize',16,...
       'fontweight','bold','color','r','verticalalign','middle');
end  


%%%%%%%%%%%%%%%%
drawnow
set(gcf,'position',[4 48 888 430]);
videotimeline(num2str(zeros(size(TIME,1),1)),it,'b')
%videotimeline(TIME,it,'b')
if prtimg
set(gcf,'color','white') 
set(findobj('tag','m_grid_color'),'facecolor','none')
set(gcf,'paperposition',[0.6 6.5 25 14]);
exportj(gcf,1,strcat(outimg,sla,titf,'.',snapshot));
end %if

                                                                                                                                                                                                                                                                                                                                                                                                                                                                    gmaze_pv/visu/eg_view_Timeserie_pl3.m                                                               0000644 0023526 0000144 00000012070 10511523556 017275  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %DEF Field projection on 3D surface


% Which variables to plot:
%wvar = [1 2 3 4 6];
wvar = [1];

for ip = 1 : length(wvar)
  
  figure(30+ip);clf;hold on;iw=1;jw=1;

% Variables loop:
  % Default:
  CBAR = 'v'; % Colorbar orientation
  Tcontour = [17 19]; Tcolor = [0 0 0]; % Theta contours
  Hcontour = -[0:200:600]; Hcolor = [0 0 0]; % MLD contours
  unit = ''; % Default unit
  load mapanom2 ; N = 256; c = [0 0]; cmap = jet; % Colormaping
  showT = 1; % Iso-Theta contours
  showW = 0; % Windstress arrows
  showH = 0; colorW = 'w'; % Mixed Layer Depth
  showCLIM = 0; % Show CLIMODE region box
  CONT  = 0; % Contours instead of pcolor
  CONTshlab = 0; % Show label for contours plot
  colorCOAST = [0 0 0]; % Land color
  
  %if it==1, mini; end 
switch wvar(ip)
  
end %switch what to plot

C = Diso;
Clon = STlon;
Clat = STlat;
% Replace land by zero:
STs = squeeze(ST(1,:,:));
%C(isnan(STs)) = 0;

C2 = Qiso;
% Replace land by zero:
Qs = squeeze(Q(1,:,:));
C2(isnan(Qs)) = 0;
% Replace ocean surface area of Diso by surface value of Q:
%C2(isnan(C)) = -10;
C2(isnan(C)) = Qs(isnan(C));

% Then replace NaN surface value of Diso by 0
C(isnan(C)) = 0;
C2(isnan(C2)) = 10;

LON = [min(Clon) max(Clon)];
LAT = [min(Clat) max(Clat)];
%LON = [277 299];
LAT = [26 40];
C = squeeze(C( max(find(Clat<=LAT(1))):max(find(Clat<=LAT(2))) ,  : ));
C = squeeze(C( : , max(find(Clon<=LON(1))):max(find(Clon<=LON(2))) ));
C2=squeeze(C2( max(find(Clat<=LAT(1))):max(find(Clat<=LAT(2))) , : ));
C2=squeeze(C2( : , max(find(Clon<=LON(1))):max(find(Clon<=LON(2)))));
Clon = squeeze(Clon( max(find(Clon<=LON(1))):max(find(Clon<=LON(2))) ));
Clat = squeeze(Clat( max(find(Clat<=LAT(1))):max(find(Clat<=LAT(2))) ));



if 0
     nlon = length(Clon);
     nlat = length(Clat);
     [lati longi] = meshgrid(Clat,Clon);
     %longi = longi';     lati = lati';
     
     new_dimension = fix([1*nlon .5*nlat]);
     n_nlon = new_dimension(1);
     n_nlat = new_dimension(2);
     n_Clon = interp1(Clon,[1:fix(nlon/n_nlon):nlon],'cubic')';
     n_Clat = interp1(Clat,[1:fix(nlat/n_nlat):nlat],'cubic')';
     [n_lati n_longi] = meshgrid(n_Clat,n_Clon);
     n_lati = n_lati'; n_longi = n_longi';
     
     n_C = interp2(lati,longi,C',n_lati,n_longi,'spline');

     n_C(find(n_C==0)) = NaN; 
     n_C = lisse(n_C,5,5);  

end %if


%C(find(C==0)) = NaN;
%C  =  lisse(C,2,2);  
%C2 = lisse(C2,2,2);       
   
% Map projection:
%m_proj('mercator','long',subdomain.limlon,'lat',subdomain.limlat);
%m_proj('mercator','long',subdomain.limlon,'lat',[25 40]);
%m_proj('mercator','long',[subdomain.limlon(1) 360-24],'lat',[25 50]);
%m_proj('mercator','long',Clon([1 length(Clon)])','lat',Clat([1 length(Clat)])');
%m_proj('mercator','long',Clon([1 length(Clon)])','lat',[15 40]);
%m_proj('mercator','long',[275 330],'lat',[15 40]);

camx = [-200:20:200];
az = [-30:10:30];
az = 5;
el = linspace(5,50,length(az));
el = 20*ones(1,length(az));

for ii = 1 : length(az)
  
clf
%surf(n_Clon,n_Clat,n_C);
s=surf(Clon,Clat,C);
%[X,Y] = m_ll2xy(Clon,Clat);
%s=surf(X,Y,C);

set(s,'cdata',C2);
  N    = 32;
  %c    = [1 30];
  %cx   = [-(1+2*c(1)) 1+2*c(2)]*1.5e-12; cmap = mapanom; cmap = jet;
  c     = [0 12];  
  cx = [-(1+2*c(1)) 1+2*c(2)]*.95*1e-9; cmap = mapanom;  %cmap = jet;
  cmap = [logcolormap(N,c(1),c(2),cmap); .3 .3 .3]; % Last value is for NaN
  %cmap = 1 - cmap;
  colormap(cmap);
  caxis(cx); %colorbar
  
  
shading interp
view(az(ii),el(ii))
%set(gca,'ylim',[15 40]);
%set(gca,'xlim',[275 330]);
grid on
xlabel('Longitude');
ylabel('Latitude');
zlabel('Depth');

%h = camlight('left'); %set(h,'color',[0 0 0]);
%camlight
l=light('position',[0 0 1]);
light('position',[0 0 -1]);
%set(h,'position',[150 -200 2000]); 
%set(h,'style','infinite')
lighting flat
material dull

%set(gca,'plotBoxAspectRatio',[2 2 .5])
%m_coast('color',[0 0 0])   
camzoom(2)
camzoom(1.25)

set(gca,'plotBoxAspectRatio',[2 2 .25])
set(gca,'visible','off');
%camzoom(1.1)
%for ix=1:length(camx)
%   set(h,'position',[camx(ix) -200 2000]); 
%   refresh;drawnow
   %M(ii) = getframe;
%end


if 0
  xlim = get(gca,'xlim');
  ylim = get(gca,'ylim');
  lC=[0 0 1];
  for x = 280:10:340
    if x >= xlim(1) & x <= xlim(2)
      line([1 1]*x,ylim,'color',lC);
    end
  end %for x
  for y = 0 : 10 : 90
    if y >= ylim(1) & y <= ylim(2)
      line(xlim,[1 1]*y,'color',lC)
    end
  end %for y
end


if 1 % Show the date in big in the upper left corner
  spp=subplot('position',[0 .95 .25 .05]);
  p=patch([0 1 1 0],[0 0 1 1],'w');
  set(spp,'ytick',[],'xtick',[]);
  set(spp,'box','off');
  dat = num2str(TIME(it,:));
  dat = strcat(dat(1:4),'/',dat(5:6),'/',dat(7:8),':',dat(9:10),'H',dat(11:12));
  text(0.1,.5,dat,'fontsize',16,...
       'fontweight','bold','color','r','verticalalign','middle');
end  

end
%return

%%%%%%%%%%%%%%%%
drawnow
set(gcf,'position',[4 48 888 430]);
%videotimeline(TIME,it,'b')
%videotimeline(num2str(zeros(size(TIME,1),1)),it,'b')
set(gcf,'color','white') 
if prtimg
%set(findobj('tag','m_grid_color'),'facecolor','none')
set(gcf,'paperposition',[0.6 6.5 25 14]);
titf='3Dview';
exportj(gcf,1,strcat(outimg,sla,titf,'.',snapshot));
end %if

%%%%%%%%%%%%%%%%%%%%%%%%%%%%




end %for ip
                                                                                                                                                                                                                                                                                                                                                                                                                                                                        gmaze_pv/visu/get_plotlistdef.m                                                                     0000644 0023526 0000144 00000002646 10513537642 016267  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
%  get_plotlistdef(MASTER,SUBDIR)
%
% This function display description of pre-defined plots
% available with the MASTER.m in the folder SUBDIR
% 
% 07/12/06
% gmaze@mit.edu

function LIST = get_plotlistdef(MASTER,SUBDIR)

global sla

% Define suffixe of plot module:
suff = '_pl';


d = dir(SUBDIR);
ii = 0;
% Select Matlab files:
for id = 1 : length(d)
  en = length( d(id).name );
  if en~=1 & (d(id).name(en-1:en) == '.m') &  ~d(id).isdir
    ii = ii + 1;
    l(ii).name = d(id).name;
  end
end

% Select Matlab files with MASTER as prefix
ii = 0;
for il = 1 : length(l)
  fil = l(il).name;
  pref = strcat(MASTER,suff);
  iM =  findstr( strcat(SUBDIR,sla,fil) , pref ) ;
  
  if ~isempty(iM)
    ii = ii + 1; 
    LIST(ii).name = l(il).name;
    LIST(ii).index = ii;
    
    % Recup description of plot module:
    fid = fopen(strcat(SUBDIR,sla,fil));
    thatsit = 0;
    while thatsit ~= 1
       tline = fgetl(fid);
       if tline ~= -1
       if length(tline)>4 & tline(1:4) == '%DEF'
          LIST(ii).description = tline(5:end);
          thatsit = 1;
       end %if
       else
          LIST(ii).description = 'Not found';
          thatsit = 1;
       end %if
    end %while
    disp(strcat( num2str(LIST(ii).index),': Module extension :',fil(length(MASTER)+2:end-2)));
    disp(strcat('|-----> description :'  , LIST(ii).description ));
    disp(char(2))
    
  end %if
  
end %for il
    
if ~exist('LIST')
  LIST= NaN;
end

                                                                                          gmaze_pv/visu/get_plotlistfields.m                                                                  0000644 0023526 0000144 00000003316 10631370426 016766  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
%  get_plotlistfields(MASTER,SUBDIR)
%
% This function returns the list of fields required by
% the modules of MASTER file in SUBDIR
% 
% 06/05/2007
% gmaze@mit.edu

function LIST = get_plotlistfields(MASTER,SUBDIR)

global sla

% Define suffixe of module:
suff = '_pl';


d = dir(SUBDIR);
ii = 0;
% Select Matlab files:
for id = 1 : length(d)
  en = length( d(id).name );
  if en~=1 & (d(id).name(en-1:en) == '.m') &  ~d(id).isdir
    ii = ii + 1;
    l(ii).name = d(id).name;
  end
end

% Select Matlab files with MASTER as prefix
ii = 0;
for il = 1 : length(l)
  fil = l(il).name;
  pref = strcat(MASTER,suff);
  iM =  findstr( strcat(SUBDIR,sla,fil) , pref );
  
  if ~isempty(iM)
    ii = ii + 1; 
    LIST(ii).name = l(il).name;
    LIST(ii).index = ii;
    
    % Recup list of fields required by the module:
    fid = fopen(strcat(SUBDIR,sla,fil));
    thatsit = 0;
    clear fiel
    while thatsit ~= 1
       tline = fgetl(fid);
       if tline ~= -1
       if length(tline)>4 & tline(1:4) == '%REQ'
	  tl = strtrim(tline(5:end));
	  if strmatch(';',tl(end)), tl = tl(1:end-1);end
	  tl = [';' tl ';'];
	  pv = strmatch(';',tl');
	  for ifield = 1 : length(pv)-1
	    fiel(ifield).name = tl(pv(ifield)+1:pv(ifield+1)-1);
	  end
          LIST(ii).nbfields = size(fiel,2);
          LIST(ii).required = fiel;
          thatsit = 1;
       end %if
       else
	  fiel.name = 'Not found';
          LIST(ii).required = fiel;
          thatsit = 1;
       end %if
    end %while
    %disp(strcat( num2str(LIST(ii).index),': Module extension :',fil(length(MASTER)+2:end-2)));
    %disp(strcat('|-----> description :'  , LIST(ii).description ));
    %disp(char(2))
    
  end %if
  
end %for il
    
if ~exist('LIST')
  LIST= NaN;
end

                                                                                                                                                                                                                                                                                                                  gmaze_pv/visu/get_plotlist.m                                                                        0000644 0023526 0000144 00000002606 10641013406 015571  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
%  LIST = get_plotlist(MASTER,SUBDIR)
%
% This function determines the list of pre-defined plots
% available with the MASTER.m in the folder SUBDIR
% LIST is a structure with name and description of each modules.
%

function LIST = get_plotlist(MASTER,SUBDIR)

global sla

% Define suffixe of plot module:
suff = '_pl';

d = dir(strcat(SUBDIR,sla));

ii = 0;
% Select Matlab files:
for id = 1 : length(d)
  en = length( d(id).name );
  if en~=1 & (d(id).name(en-1:en) == '.m') &  ~d(id).isdir
    ii = ii + 1;
    l(ii).name = d(id).name;
  end
end


% Select Matlab files with MASTER as prefix
ii = 0;

for il = 1 : size(l,2)
  fil = l(il).name;
  pref = strcat(MASTER,suff);
  iM =  findstr( strcat(SUBDIR,sla,fil) , pref ) ;
  
  if ~isempty(iM)
    ii = ii + 1; 
    LIST(ii).name = l(il).name;
    LIST(ii).index = ii;
    
    % Recup description of plot module:
    fid = fopen(strcat(SUBDIR,sla,fil));
    if fid < 0
      sprintf('Problem with file: %s',strcat(SUBDIR,sla,fil))
      return
    end
    thatsit = 0;
    while thatsit ~= 1
       tline = fgetl(fid);
       if tline ~= -1
       if length(tline)>4 & tline(1:4) == '%DEF'
          LIST(ii).description = tline(5:end);
          thatsit = 1;
       end %if
       else
          LIST(ii).description = 'Not found';
          thatsit = 1;
       end %if
    end %while
    
  end %if
  
end %for il
    
if ~exist('LIST')
  LIST= NaN;
end
                                                                                                                          gmaze_pv/visu/grid_setup.m                                                                          0000644 0023526 0000144 00000004711 10506557107 015237  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  % Here we define as global variables grids for u, v, theta and salt
% and also sub domain for the CLIMODE North Atlantic study


function grid_setup

global domain subdomain1 subdomain2 subdomain3 subdomain4


% Load grid

GRID_125

% Setup standard grid variables:

lon_salt=lon125;
lon_thet=lon125;
lon_u=[lon125(1)-360+lon125(end) (lon125(2:end)+lon125(1:end-1))/2];
lon_v=lon125;

lat_salt=lat125';
lat_thet=lat125';
lat_u=lat125';
lat_v=[lat125(1)-(lat125(2)-lat125(1))/2 (lat125(1:end-1)+lat125(2:end))/2]';

dpt_salt=dpt125;
dpt_thet=dpt125;
dpt_u=dpt125;
dpt_v=dpt125;
dpt_w=[0 cumsum(thk125(1:end-1))];


% Define the domain with structure:
domain = struct(...
                'SALTanom',struct('lon',lon_salt,'lat',lat_salt','dpt',dpt_salt),...
                'THETA',   struct('lon',lon_thet,'lat',lat_thet','dpt',dpt_thet),...
                'UVEL',   struct('lon',lon_u,'lat',lat_u','dpt',dpt_u),...
                'VVEL',   struct('lon',lon_v,'lat',lat_v','dpt',dpt_v),...
                'WVEL',   struct('lon',lon_salt,'lat',lat_salt','dpt',dpt_w)...
	        );



% And here we define the subdomain global structure containing 3D limits
% of the studied region, defined on the central grid.

sub_name='western_north_atlantic';
lonmin=lon125(2209); 
lonmax=lon125(2401); 
latmin=lat125(1225); 
latmax=lat125(1497); 
dptmin=dpt125(1);    
dptmax=dpt125(29);   

subdomain1=struct('name',sub_name,...
		 'limlon',[lonmin lonmax],...
		 'limlat',[latmin latmax],...
		 'limdpt',[dptmin dptmax]);


sub_name='climode';
lonmin=lon125(2312); % = 332E
lonmax=lon125(2384); % = 306E
latmin=lat125(1368); % = 27N
latmax=lat125(1414); % = 50N
dptmin=dpt125(1);    % = 5m
dptmax=dpt125(29);   % = 1105.9m

subdomain2=struct('name',sub_name,...
		 'limlon',[lonmin lonmax],...
		 'limlat',[latmin latmax],...
		 'limdpt',[dptmin dptmax]);


sub_name='north_atlantic';
lonmin=lon125(2209); 
lonmax=lon125(2880); 
latmin=lat125(1157); 
latmax=lat125(1564); 
dptmin=dpt125(1);    
dptmax=dpt125(29);   

subdomain3=struct('name',sub_name,...
                 'limlon',[lonmin lonmax],...
                 'limlat',[latmin latmax],...
                 'limdpt',[dptmin dptmax]);


sub_name='global';
lonmin=lon125(1); 
lonmax=lon125(2880); 
latmin=lat125(1); 
latmax=lat125(2176); 
dptmin=dpt125(1);    
dptmax=dpt125(29);   

subdomain4=struct('name',sub_name,...
                 'limlon',[lonmin lonmax],...
                 'limlat',[latmin latmax],...
                 'limdpt',[dptmin dptmax]);
                                                       gmaze_pv/visu/logcolormap.m                                                                         0000644 0023526 0000144 00000002676 10454542255 015420  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% cmap = logcolormap(Ncol,c1,c2,cmapO)
%
%
% 07/10/06
% gmaze@mit.edu

function cmap = logcolormap(Ncol,c1,c2,cmapO);

cmapO = mycolormap(cmapO,Ncol);

colD = [1 1 1];
colU = [0 0 0];


cmapD = [linspace(colD(1),cmapO(1,1),c1*Ncol) ; ...
	 linspace(colD(2),cmapO(1,2),c1*Ncol) ; ...
	 linspace(colD(3),cmapO(1,3),c1*Ncol)]';
%cmapD = ones(c1*Ncol,3)*0;



cmapU = [linspace(cmapO(Ncol,1),colU(1),c2*Ncol) ; ...
	 linspace(cmapO(Ncol,2),colU(2),c2*Ncol) ; ...
	 linspace(cmapO(Ncol,3),colU(3),c2*Ncol)]';
%cmapU = ones(c2*Ncol,3)*0;


if c1 == 0 & c2 ~= 0
cmap = [...
        cmapO ; ...
	cmapU ; ...
       ];
end

if c1 ~= 0 & c2 ==0
cmap = [...
	cmapD ; ...
        cmapO ; ...
       ];
end
  
if c1 ~= 0 & c2 ~= 0  
cmap = [...
	cmapD ; ...
        cmapO ; ...
	cmapU ; ...
       ];
end

if c1 == 0 & c2 == 0  
cmap = [cmapO];
end

cmap = [cmapD;cmapO;cmapU];

if 0
n = ceil(Ncol/4);
u1 = [(1:1:n)/n ones(1,n-1) (n:-1:1)/n]';

x = log( linspace(1,exp(1),n) ).^2;
%u = [x ones(1,n-1) (n:-1+dx:1)/n]';
u = [x ones(1,n-n/2) fliplr(x)]';



g = ceil(n/2) - (mod(Ncol,4)==1) + (1:length(u1))';

%b = - (1:length(u))'  ;

b = g - n ;
r = g + n ;

r(r>Ncol) = [];
g(g>Ncol) = [];
b(b<1)    = [];

cmap      = zeros(Ncol,3);
cmap(r,1) = u1(1:length(r));
cmap(g,2) = u1(1:length(g));
cmap(b,3) = u1(end-length(b)+1:end);
end




if 0
% Set the colormap:
clf;colormap(cmap);
hold on
plot(cmap(:,1),'r*-');
plot(cmap(:,2),'g*-');
plot(cmap(:,3),'b*-');
colorbar
grid on
end
                                                                  gmaze_pv/visu/mapclean.m                                                                            0000644 0023526 0000144 00000002054 10453230731 014640  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% SUBFCT_MAPCLEAN(CPLOT,CBAR)
%
% This function makes uniformed subplots (handles CPLOT)
% and their vertical colorbars (handles CBAR)
%
% 07/06/06
% gmaze@mit.edu

function subfct_mapclean(CPLOT,CBAR)


np = length(CPLOT);
proper1 = 'position';
proper2 = 'position';

% Get positions of subplots and colorbars:
for ip = 1 : np
  Pot(ip,:) = get(CPLOT(ip),proper1);
  Bot(ip,:) = get(CBAR(ip),proper2);
end


% Set coord of subplots: [left bottom width height]
W = max(Pot(:,3));
H = max(Pot(:,4));
Pot;
for ip = 1 : np
  set(CPLOT(ip),proper1,[Pot(ip,1:2) W H]);
end


% Get new positions of subplots:
for ip = 1 : np
  Pot(ip,:) = get(CPLOT(ip),proper1);
end


% Fixe colorbars coord: [left bottom width height]
Wmin = 0.0435*min(Pot(:,3));
Hmin = 0.6*min(Pot(:,4));

% Set them:
for ip = 1 : np
  %set(CBAR(ip),proper2,[Bot(ip,1) Bot(ip,2) Wmin Hmin]);
%  set(CBAR(ip),proper2,[Pot(ip,1)+Pot(ip,3)*1.1 Pot(ip,2)+Pot(ip,2)*0.1 Wmin Hmin]);
  set(CBAR(ip),proper2,[Pot(ip,1)+Pot(ip,3)*1.05 Pot(ip,2)+Pot(ip,4)*0.2 ...
		        0.0435*Pot(ip,3) 0.6*Pot(ip,4)])
end
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    gmaze_pv/visu/videotimeline.m                                                                       0000644 0023526 0000144 00000001704 10453551212 015716  0                                                                                                    ustar   gmaze                           users                                                                                                                                                                                                                  %
% [] = videotimeline(TIMERANGE,IT,POSITION)
%
% TIMERANGE contains all the time line serie
% TIME contains the current time
%

function varargout = videotimeline(TIME,it,POSIT)


[nt nc] = size(TIME);

DY = .02;
DX = 1/nt;

bgcolor=['w' 'r'];
bdcolor=['k' 'r'];
txtcolor=['k' 'w'];
fts = 8;

figure(gcf);hold on

for ii = 1 : nt
  %p=patch([ii-1 ii ii ii-1]*DX,[1 1 0 0]*DY,'w');
  if POSIT == 't'
    s=subplot('position',[(ii-1)*DX 1-DY DX DY]);
  else
    s=subplot('position',[(ii-1)*DX 0 DX DY]);
  end
  p=patch([0 1 1 0],[0 0 1 1],'w');
  set(s,'ytick',[],'xtick',[]);
  set(s,'box','on');
  tt=text(.35,0.5,TIME(ii,:));
  
  if ii == it
    set(p,'facecolor',bgcolor(2));
    set(p,'edgecolor',bdcolor(2));
    %set(s,'color',bgcolor(2));
    set(tt,'fontsize',fts,'color',txtcolor(2));
  else
    set(p,'facecolor',bgcolor(1));
    set(p,'edgecolor',bdcolor(1));
    %set(s,'color',bgcolor(1));
    set(tt,'fontsize',fts,'color',txtcolor(1));
  end
end
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            