fid = fopen('/scratch/general/am8e13/cs_36km_tutorial/run_year/LATC.bin', 'r', 'b' ); data = fread( fid, 'real*4' ); fclose(fid);
lat = reshape(data,210,192);

fid = fopen('/scratch/general/am8e13/cs_36km_tutorial/run_year/LONC.bin', 'r', 'b' ); data = fread( fid, 'real*4' ); fclose(fid);
lon = reshape(data,210,192);

%nccreate('lat.nc','lat');
%ncwrite('lat.nc','lat',lat);
%ncdisp('latlon.nc');

[fid] = fopen( 'lat_mit', 'w', 'b' );
fwrite(fid,lat,'real*4');
fclose(fid);

[fid] = fopen( 'lon_mit', 'w', 'b' );
fwrite(fid,lon,'real*4');
fclose(fid);