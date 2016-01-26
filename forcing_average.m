% This routine calculates averages of forcing fields

% filename is the first part of the file 'jra25_something'/ERA40g_something
% nx =320 ny = 160 in this case
% accuracy for this case is 'real*4'
close all ; clear all ;

np = 16 ; %number of years records
file_name = 'cube78' ; %'jra25' ; % or ERA40g
nx =320; ny = 160;
accuracy = 'real*4' ;
start_year = 1991 ;

%cd /scratch/general/am8e13/cs_36km_tutorial/climdata/
%cd /scratch/general/am8e13/ERA_data/
cd /scratch/general/am8e13/NCEP_data/

variables = {'v10m', 'u10m', 'dlw', 'dsw', 'tmp2m_degC', 'spfh2m', 'rain'};

for k = 1:length(variables)
    datatot = 0 ;
    var = variables{k} ;
    fprintf('Now reading %s \n',var)
    
    for i = 1: np
        year = start_year + i;
        file_name_complete = strcat(file_name,'_',num2str(var),'_',num2str(year));
        fprintf('now reading %s \n',file_name_complete)
        fid = fopen( file_name_complete, 'r', 'b' );   

        % Read in the data.                                                                                                               
        data = fread( fid, accuracy ); 
        fclose(fid);
        
        % Reduce year from 365/366 days to 360: randomly select 5/6 days
        % and cancel
        if length(data)==nx*ny*365*4
            days = 365;
            n_pop = 5 ;
        elseif length(data)==nx*ny*366*4
            days = 366;
            n_pop = 6;
            fprintf('Its a leap year! \n')
        else
            fprintf('dimension of file incorrect')
        end
        
        data = reshape( data, nx, ny, days*4 );
        daystopop = randperm(days,n_pop) ;  
        for i = 1:length(daystopop)
            topop((i-1)*4+1:(i-1)*4+4) = (daystopop(i)*4-3):(daystopop(i)*4) ;
        end
        
        datatemp = data ;
        data(:,:,topop) = [] ;
        fprintf('datatemp %s, datatot %s, data %s, topop %s, daystopop %s \n',num2str(size(data,3)),num2str(size(datatot,3)),num2str(size(data,3)),num2str(size(topop)),num2str(size(daystopop)))
        datatot = datatot + data ;        
        topop = [] ; daystopop = []; days = [] ; n_pop = [] ;
        
    end
    datatot = datatot/np ;
    dataav = reshape(datatot,360*4*nx*ny,1);
    file_name_complete = strcat(file_name,'_',num2str(var),'_average') ;
    [fid] = fopen( file_name_complete, 'w', 'b' );
    fwrite(fid,dataav,accuracy);
    fclose(fid);
    
end