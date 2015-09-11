% read obcs
addpath ~/MITgcm_mio/

%cd /scratch/general/am8e13/  /
pin = '/scratch/general/am8e13/obcs_9km/' ;
pout ='/scratch/general/am8e13/obcs_9km/' ;

accuracy = 'real*8';
res = 9 ;

if res == 18
    text_res = '420x384' ; % or '210x192'
    nx = 420 ;
    ny = 384 ;
elseif res == 36
    text_res = '210x192' ; % or '420x384'
    nx = 210 ;
    ny = 192 ;
elseif res == 9
    text_res = '840x768';
    nx = 840 ;
    ny = 768 ;
end

nz = 50 ;
nt = 12 ;

for pos = ['W','N','E']
    for var = ['s','t','v','u']
        if (var == 'u') || ( var == 'v')
            if (var == 'v') && (pos == 'N')
                %last = 'balance';
                 last = 'bin' ;
                 middle = '_clim' ;
            else
                last = 'bin';
                middle = '_clim' ;
            end
        elseif (var == 's') || (var == 't')
            last = 'stable';
            middle = '_WOA05' ;
        end

    file_name = strcat('OB',num2str(pos),num2str(var),'_arctic_',num2str(text_res),'.',num2str(last),'_mean');

    fprintf('now reading %s \n',file_name)
    fprintf('path is %s \n', strcat(pin,file_name))
    if pos == 'W' || pos == 'E'
        n = ny ;
    elseif pos == 'N'
        n = nx ;
    end

    tmpin=readbin([pin file_name],[n nz nt]);

    dataav = zeros(n,50,12) ;
    
    if (var == 't')
      dataav_tempmod = zeros(size(tmpin)) ;
        for i = 1 : 12
            %dataav_tempmod(:,:,i) = (0.4*tmpin(:,:,i)+ (0.2*tmpin(:,:,3)+0.2*tmpin(:,:,4)+0.2*tmpin(:,:,5)));
            dataav_tempmod(:,:,i) = (0.7*tmpin(:,:,i)+ (0.1*tmpin(:,:,3)+0.1*tmpin(:,:,4)+0.1*tmpin(:,:,5))); 
            
            
        end
            %dataav_tempmod = dataav_tempmod*0.6;
            dataav_tempmod(dataav_tempmod>0) = dataav_tempmod(dataav_tempmod>0)*0.5;
                filename_mod = strcat(file_name,'_tempmod1') ;
                writebin([pout filename_mod],dataav_tempmod)
    
        end
    end
end

cd ~/MITgcm_mio
