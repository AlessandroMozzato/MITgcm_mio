% vorticity calculation

 %vel = rdmnc('dynDiag.*','VVEL','UVEL') ;
 %coord = rdmnc('state.*','XC','YX','ZC') ;
 
 close all
 
 depth = 1;
 time = 36 ; 
 
 u = mean(vel.UVEL(1:end-1,:,depth,time),4) ;
 v = mean(vel.VVEL(:,1:end-1,depth,time),4) ;
 vortic = squeeze(vort.momVort3(:,:,depth,time)) ;
 hdiv = squeeze(vort.momHDiv(:,:,depth,time)) ;
 ke = squeeze(vort.momKE(:,:,depth,time)) ;

 
 %  dx = grid.dyC(:,1) ;
%  dy = grid.dxC(1,:) ;
%   
%  for kk = 2 : size(u,1)-1
%   for hh = 2 : size(u,2)-1
%       
%       vort_calc(kk,hh) = (v(kk,hh+1) - v(kk,hh-1))/dx(kk) - (u(kk+1,hh) - u(kk-1,hh)/dy(hh)) ;
%       
%   end
%  end
%  
 minnn = min(min(min(vort_calc)),min(min(vortic))) ;
 maxxx = max(max(max(vort_calc)),max(max(vortic))) ;
  
 figure(1)
 subplot(1,3,1)
 imagesc(vortic')
 colorbar
 
 subplot(1,3,2)
 imagesc(ke')
 colorbar

 subplot(1,3,3)
 imagesc(hdiv') ; colorbar