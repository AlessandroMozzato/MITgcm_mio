function [obcsrecalc] = recalc_obcs(data,hfacc,pos,var,nx,ny)

% this function calculate total and temporal flux from open boundary
% conditions

obcsrecalc = zeros(size(data)) ;

for i = 1 : size(data,3)
    datatemp = data(:,:,i);
    if pos == 'N'
        if var == 'u'
            datatemp(hfacc(1:nx,ny,:)==0) = 0 ;            
        elseif var == 'v'
            datatemp(hfacc(1:nx,ny,:)==0) = 0 ;
        end
    elseif pos == 'E'
        if var == 'u'
            datatemp(hfacc(nx,1:ny,:)==0) = 0 ;
        elseif var == 'v'
            datatemp(hfacc(nx,1:ny,:)==0) = 0 ;
        end
    elseif pos == 'W'  
        if var == 'u'
            datatemp(hfacc(2,1:ny,:)==0) = 0 ;
        elseif var == 'v'
            datatemp(hfacc(2,1:ny,:)==0) = 0 ;
        end
    end
    
    obcsrecalc(:,:,i) = datatemp ;
end