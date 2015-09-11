ieee='b';
prec='real*4';

fid = fopen( 'initS', 'r', 'b' );   

% Read in the data.                                                                                                               
initS = fread( fid, prec ); 
fclose(fid);

initS = reshape(initS,210,192,50);

max(max(max(initS)))