function dataav = plot_data( file_name_complete, nx, ny, accuracy )

% filename is the first part of the file 'jra25_something'
% nx =320 ny = 160 in this case
% accuracy for this case is 'real*4'

%cd /scratch/general/am8e13/cs_36km_tutorial/climdata/
cd /scratch/general/am8e13/cs_36km_tutorial/clim_year/

fid = fopen( file_name_complete, 'r', 'b' );   

% Read in the data.                                                                                                               
data = fread( fid, accuracy ); 
fclose(fid);

plot(data)

cd ~/MITgcm_mio/

end