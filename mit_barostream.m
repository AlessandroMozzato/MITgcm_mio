function [psi, psimask] = mit_barostream();
%function [psi, psimask] = mit_barostream(u,umask,dy,dz);
% or
%function [psi, psimask] = mit_barostream(u,gridinformation);
% global barotropic stream function for mitgcm model, time slabs are
% handled as cell objects, integration from north to the south (by
% convention). 

%   if nargin == 2
%     g = varargin{1};
%     umask = g.umask;
%     dy = g.dyg;
%     dz = g.dz;
%   elseif nargin == 4
%     umask = varargin{1};
%     dy = varargin{2};
%     dz = varargin{3};
%   else
%     error('need 2 (one of which is the grid structure) or 4 arguments')
%   end

umask = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ; 
dy = ncread('/scratch/general/am8e13/results36km/grid.nc','dyG') ; 
dy = dy(1:210,:);
dz = ncread('/scratch/general/am8e13/results36km/grid.nc','Z') ;
U = ncread('/scratch/general/am8e13/results2_multitrac36km/state.nc','U') ;
%ustruct = load('U.mat') ;
%u = ustruct.U ;
u = U(1:210,1:192,:,:);

  [nx ny nz] = size(umask);
  for kz=1:nz
    dydzs(:,:,kz) = (umask(:,:,kz).*dy)*dz(kz);
  end

  % mask for stream function
  pmask = squeeze(umask(:,:,1));
  pmask(pmask==NaN)= 0 ;
  % add psi-point to the north of all wet points
  pmask(1:nx,2:ny) = pmask(1:nx,2:ny)+pmask(1:nx,1:ny-1);
  pmask(pmask == 0) = NaN ;
  pmask(pmask ~= NaN) = 1;
  % integrate from the north to the south (by convention), change
  % integration direction by flipping the array ubar (transposed because
  % of MITgcm conventions)
    nt = size(u,4);
    psi = repmat(NaN,[nx ny nt]);
    udxdz = u(1:210,:,:,:).*repmat(dydzs,[1 1 1 nt]);
    udxdz(udxdz == NaN) = 0 ;
    ubar = squeeze(sum(udxdz,3));
    for kt = 1:nt
      psi(:,:,kt) = fliplr(cumsum(fliplr(squeeze(ubar(:,:,kt))),2)).*pmask;
    end
    
  if nargout == 2
    psimask = pmask;
  end
    
  return