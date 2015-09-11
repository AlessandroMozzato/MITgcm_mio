function [flux_sum,flux] = flux_calc(vel,pos,var,dxdz_u,dxdz_v,dydz_u,dydz_v,nx,ny)

% this function calculate total and temporal flux from open boundary
% conditions

flux = zeros(1,size(vel,3)) ;

for i = 1 : size(vel,3)
    
    if pos == 'N'
        if var == 'u'
            flux(i) = mean(mean(vel(:,:,i).*squeeze(dxdz_u(1:nx,ny,:)))) ;            
        elseif var == 'v'
            flux(i) = mean(mean(vel(:,:,i).*squeeze(dxdz_v(1:nx,ny,:)))) ;
        end
    elseif pos == 'E'
        if var == 'u'
            flux(i) = mean(mean(vel(:,:,i).*squeeze(dydz_u(nx+1,1:ny,:)))) ;
        elseif var == 'v'
            flux(i) = mean(mean(vel(:,:,i).*squeeze(dydz_v(nx,1:ny,:)))) ;            
        end
    elseif pos == 'W'  
        if var == 'u'
            flux(i) = mean(mean(vel(:,:,i).*squeeze(dydz_u(2,1:ny,:)))) ;
        elseif var == 'v'
            flux(i) = mean(mean(vel(:,:,i).*squeeze(dydz_v(2,1:ny,:)))) ;
        end
    end
    
end

flux_sum = sum(flux) ;