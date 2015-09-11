% [V,Cm,E,Vt,CC] = diagVOLUinterp(PII,B,dV,C,DX,DY,DZ,Tc,dT)
%
% DESCRIPTION:
% Compute the volume of water embeded in Tc-dT/2 <= C < Tc+dT/2
% by interpolation of grid fraction
%
% INPUTS: 
% PII: 0/1 matrix defining the volume
% B  : 0/1 matrix defining the boundary's volume (from getVOLbounds)
% dV : Volume elements matrix
% C  : Input field used to get PII, of size: ndpt x nlat x nlon
% DX : zonal grid spacing of size: ndpt x nlat x nlon+1
% DY : meridional grid spacing of size: ndpt x nlat+1 x nlon
% DZ : vertical grid spacing of size: ndpt+1 x nlat x nlon
% Tc : the iso-C contour
% dT : the bin used to get PII
%
% OUTPUTS:
% V       : Interpolated volume of the layer
% Vraw    : Raw volume, as returned by diagVOLU
%
% EG of use:
% Tc = 18; dT = 2;
% pii = boxcar(THETA,-10000,lon,lat,dpt,Tc,dT);
% [BN BS BW BE BT BB]=getVOLbounds(pii); B=BN+BS+BE+BW+BT+BB; B(find(B~=0)) = 1;
% [Vi Vr]=diagVOLUinterp(pii,B,dV_3D,THETA,DX,DY,DZ,Tc,dT)
%
%
% AUTHOR: 
% Guillaume Maze / MIT
% 
% HISTORY:
% - Created: 07/24/2007
%

% 

function varargout = diagVOLUinterp(pii,B,dV_3D,THETA,DX,DY,DZ,Tc,dT)

ndpt = size(THETA,1);
nlat = size(THETA,2);
nlon = size(THETA,3);

% Raw value of the volume:
Vraw = nansum(nansum(nansum( pii.*dV_3D)));

% Raw value without boundary points:
Vraw_interior = nansum(nansum(nansum( (pii-B).*dV_3D)));

ii = 0;
npt = length(find(B==1));
dV    = 0;
dVraw = 0;
warning off
for iz = 1 : ndpt
 for ix = 1 : nlon
  for iy = 1 : nlat
    if B(iz,iy,ix) == 1
      ii = ii + 1;
      %disp(sprintf('%d/%d/pii=%d',npt,ii,pii(iz,iy,ix)));
      Tloc = THETA(iz,iy,ix);
      clear T
      
      % Northern value:
      dyn  = DY(iy+1,ix); c = 1/2;
      if iy+1 < nlat & isnan(THETA(iz,iy+1,ix)) == 0
	T = THETA(iz,iy+1,ix);
	alphan = (dT/2 - abs(Tloc-Tc))./( abs(T-Tc) - abs(Tloc-Tc) );
        if alphan > 1/2 & pii(iz,iy+1,ix) ~= 1 & ~isinf(alphan)
   	  c = alphan-1/2;
	end
      end
      dyn = dyn*c;
      
      % Southern value:
      dys = DY(iy,ix); c = 1/2;
      if iy-1 > 1 & isnan(THETA(iz,iy-1,ix)) == 0
	T = THETA(iz,iy-1,ix);
	alphas = (dT/2 - abs(Tloc-Tc))./( abs(T-Tc) - abs(Tloc-Tc) );
        if alphas > 1/2 & pii(iz,iy-1,ix) ~= 1 & ~isinf(alphas)
	  c = alphas-1/2;
	end
      end
      dys = dys*c;

      % Eastern value:
      dxe = DX(iy,ix+1); c = 1/2;
      if ix+1 < nlon & isnan(THETA(iz,iy,ix+1)) == 0
	T = THETA(iz,iy,ix+1);
	alphae = (dT/2 - abs(Tloc-Tc))./( abs(T-Tc) - abs(Tloc-Tc) );
        if alphae > 1/2 & pii(iz,iy,ix+1) ~= 1 & ~isinf(alphae)
	  c = alphae-1/2;
	end
      end
      dxe = dxe*c;
      
      % Western value:
      dxw = DX(iy,ix); c = 1/2;
      if ix-1 > 1 & isnan(THETA(iz,iy,ix-1)) == 0
	T = THETA(iz,iy,ix-1);
	alphaw = (dT/2 - abs(Tloc-Tc))./( abs(T-Tc) - abs(Tloc-Tc) );
        if alphaw > 1/2 & pii(iz,iy,ix-1) ~= 1 & ~isinf(alphaw)
	  c = alphaw-1/2;
	end
      end
      dxw = dxw*c;
      
      % Top value:
      dzt = DZ(iz); c = 1/2;
      if iz-1 > 1 & isnan(THETA(iz-1,iy,ix)) == 0
	T = THETA(iz-1,iy,ix);
	alphat = (dT/2 - abs(Tloc-Tc))./( abs(T-Tc) - abs(Tloc-Tc) );
        if alphat > 1/2 & pii(iz-1,iy,ix) ~= 1 & ~isinf(alphat)
	  c = alphat-1/2;
	end
      end
      dzt = dzt*c;
      
      % Bottom value:
      dzb = DZ(iz+1); c = 1/2;
      if iz+1 > 1 & isnan(THETA(iz+1,iy,ix)) == 0
	T = THETA(iz+1,iy,ix);
	alphab = (dT/2 - abs(Tloc-Tc))./( abs(T-Tc) - abs(Tloc-Tc) );
        if alphab > 1/2 & pii(iz+1,iy,ix) ~= 1 & ~isinf(alphab)
	  c = alphab-1/2;
	end
      end
      dzb = dzb*c;
      
      dV(ii)    = (dxw+dxe)*(dys+dyn)*(dzt+dzb);
      dVraw(ii) = dV_3D(iz,iy,ix);
      
    end %if boundary point
  end %for iy
 end %for ix
end %for iz
warning on
Vraw2    = Vraw_interior + sum(dVraw);
Vinterp  = Vraw_interior + sum(dV);

if Vraw2 ~= Vraw & 0
  warning(sprintf('diagVOLUinterp: Raw volumes doesn''t match ! \n Difference in %%: %g',...
		  (Vraw2-Vraw)/Vraw*100))
end

% 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OUTPUTS
switch nargout
 case 1
  varargout(1) = {Vinterp};
 case 2
  varargout(1) = {Vinterp};
  varargout(2) = {Vraw2};
end %switch



