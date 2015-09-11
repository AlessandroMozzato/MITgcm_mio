% read obcs
addpath ~/MITgcm_mio/
%cd /scratch/general/am8e13/matlab_obcs/+OB1992_2010/
pin = '/scratch/general/am8e13/obcs_9km/' ;
pout = '/scratch/general/am8e13/obcs_9km/' ;

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
nt = 230 ;

for pos = ['W','N','E']
    for var = ['s','t','v','u']
        if (var == 'u') || ( var == 'v')
            if (var == 'v') && (pos == 'N')
                last = 'balance';
                %last = 'bin' ;
                middle = '_clim' ;
            else
                last = 'bin';
                middle = '_clim' ;
            end
        elseif (var == 's') || (var == 't')
            last = 'stable';
            middle = '_WOA05' ;
        end

        file_name = strcat('OB',num2str(pos),num2str(var),'_arctic_',num2str(text_res),'.',num2str(last));

        fprintf('now reading %s \n',file_name)

        if pos == 'W' || pos == 'E'
            n = ny ;
        elseif pos == 'N'
            n = nx ;
        end

        tmpin=readbin([pin file_name],[n nz nt]);

        dataav = zeros(n,50,12) ;

        for k = 1:228
            kk = mod(k,12) ;
            if kk == 0
                kk = 12 ;
            end
           dataav(:,:,kk) = dataav(:,:,kk) + tmpin(:,:,k) ;
        end

        dataav = dataav/19 ;
        file_name = strcat(file_name,'_mean');
        writebin([pout file_name],dataav)
        % datares = reshape(dataav,n*50*12,1);
        % %figure(1)
        % %plot(datares -data(length(datares)*3+1:4*length(datares)))
        % %  
        % file_name_complete = strcat(file_name) ;
        % 
        % [fid] = fopen( '/scratch/general/am8e13/matlab_obcs/+OB1992_2010_average/',file_name_complete, 'w', 'b' );
        % fwrite(fid,datares,accuracy);
        % fclose(fid);

    end
end
cd ~/MITgcm_mio
