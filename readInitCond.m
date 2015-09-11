
cd /scratch/general/am8e13/cs_36km_tutorial/run_year/   
fid = fopen( 'WOA05_SALT_JAN_210x192x50_arctic', 'r', 'b' );   

% Read in the data.                                                                                                               
data = fread( fid ,'real*4'); 
fclose(fid);
                                                                                         
data = reshape( data, 210, 192, 50 );

cd ~

