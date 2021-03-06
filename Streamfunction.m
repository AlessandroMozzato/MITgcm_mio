% Time averaged Eulerian Streamfunction

function [Psi] = Streamfunction(vel)

close all
clear all

%state = rdmnc('state.*') ;
vel = rdmnc('state.*','V','U','W') ;
grid = rdmnc('grid.*','Y','X','Z','HFacS','HFacW','HFacC','XC') ;
%nn = length(state.iter) ;

Z = grid.Z' ;
Y = grid.Y ;
V = vel.V ;
dx = (grid.XC(2,1)-grid.XC(1,1)) ;
lm = grid.HFacS ;

%Depth integration
dz = Z(1:end-1)-Z(2:end) ;
dz = [0-Z(1);dz] ;
V = squeeze(nanmean(V(:,:,:,1:end-1),4)).*lm ;
% inverting order
Vf = V(:,:,end:-1:1) ;
dzf = dz(end:-1:1) ;
% Zonally integrate
Vfdx = squeeze(nansum(Vf*dx)) ;

% Depth integration
Vfdx(Vfdx==0)=NaN;
Vdz = zeros(length(Y),length(Z)+1) ;

for i = 1 : length(Y)
    Vdz(i,2:length(Z)+1)=squeeze(Vfdx(i,:)).*dzf';
end

Psi = nancumsum(Vdz,2) ; % Sum up the water column
Psi = Psi(:,end:-1:1) ; % Reorder
  
    pcolor(Y/1000,[Z;Z(end)-250],Psi(:,1:length(Z)+1)');  %can add ,15 to add more contours
    shading flat
    cmax=max(max((Psi(:,1:length(Z)+1)))) ;
    cmin=min(min((Psi(:,1:length(Z)+1)))) ;
    colormap(b2r(cmin,cmax)) 
    xlabel('Meridional distance (km)','fontsize',12)
    ylabel('Depth (m)','fontsize',12)
    title(' Eulerian mean overturning','fontsize',12)
    h=colorbar;
    ylabel(h,'Transport (Sv)','fontsize',12)
% 

end