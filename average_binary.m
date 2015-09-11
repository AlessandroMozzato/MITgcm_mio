function dataav = average_binary( file_name, nx, ny, accuracy )

% filename is the first part of the file 'jra25_something'
% nx =320 ny = 160 in this case
% accuracy for this case is 'real*4'

datatot = 0 ;
np = 25 ; %number of years records

cd /scratch/general/am8e13/ERA_data/

for i = 1: np

    year = 1978 + i;

file_name_complete = strcat(file_name,'_',num2str(year));

fprintf('now reading %s \n',file_name_complete)

fid = fopen( file_name_complete, 'r', 'b' );   

% Read in the data.                                                                                                               
data = fread( fid, accuracy ); 
fclose(fid);

if length(data)==74752000
                                                                                                                                  
% Reshape the data from a single column.                                                                                          
data = reshape( data, nx, ny, 365*4 ); 

data(:,:,101:104) = [] ;
data(:,:,301:304) = [] ;
data(:,:,501:504) = [] ;
data(:,:,701:704) = [] ;
data(:,:,901:904) = [] ;

elseif length(data)==74956800
    
data = reshape( data, nx, ny, 366*4 ); 

data(:,:,101:104) = [] ;
data(:,:,301:304) = [] ;
data(:,:,501:504) = [] ;
data(:,:,701:704) = [] ;
data(:,:,901:904) = [] ;
data(:,:,1001:1004) = [] ;

fprintf('its a leap year! \n')

else
fprintf('dimension of file incorrect')
return

end

datatot = datatot + data ;

end

datatot = datatot/np ;

cd /scratch/general/am8e13/cs_36km_tutorial/clim_year/

dataav = reshape(datatot,360*4*nx*ny,1);

file_name_complete = strcat(file_name,'_average_new') ;

[fid] = fopen( file_name_complete, 'w', 'b' );
fwrite(fid,dataav,accuracy);
fclose(fid);