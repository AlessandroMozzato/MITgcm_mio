% check river runoff 
accuracy = 'real*4' ;

fid = fopen( '/hpcdata/scratch/am8e13/cs_36km_tutorial/run_input/runoff-360x180x12.bin', 'r', 'b' );    
original_runoff = fread( fid, accuracy ); 
fclose(fid);

fid = fopen( '/hpcdata/scratch/am8e13/CORE_data/runoff-corev2_360x180x12.bin', 'r', 'b' );    
core_runoff = fread( fid, accuracy ); 
fclose(fid);

original_runoff = reshape(original_runoff,360,180,12) ;
core_runoff = reshape(core_runoff,360,180,12) ;