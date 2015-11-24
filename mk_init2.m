nx=420; ny=384; nx2=840; ny2=768;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);
% Open the nc file.
ncid = netcdf.open('/hpcdata/scratch/am8e13/arctic420x384/run_tempcorr/toglue/state.nc', 'NOWRITE' );
% Load the required fiels
S = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 0 ], [ nx ny 50 1 ] );
T = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 0 ], [ nx ny 50 1 ] );

% Open the nc file.
ncid = netcdf.open('/scratch/general/am8e13/results9km/grid.nc', 'NOWRITE' );
% Load the required fiels
bathy = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacC' ), [ 0 0 0 ], [ nx2 ny2 50 ] );

save bathy bathy

save T T
save S S
tempS = zeros(nx2,ny2,50);
tempT = zeros(nx2,ny2,50);

fout=['/noc/users/am8e13/MITgcm_mio/THETA_840x768_from18km'];
fin = T;
for k=1:50
    %tmp(2:(nx+1),2:(ny+1))=readbin(fin,[nx ny],1,'real*4',k-1);
    tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
    tmp(1,:)=tmp(2,:);
    tmp(nx+2,:)=tmp(nx+1,:);
    tmp(:,1)=tmp(:,2);
    tmp(:,ny+2)=tmp(:,ny+1);
    tmp2=interp2(y,x',tmp,y2,x2');
    tempT(:,:,k)=tmp2;           
    writebin(fout,tmp2,1,'real*4',k-1)
  end
save tempT tempT

fout=['/noc/users/am8e13/MITgcm_mio/SALT_840x768_from18km'];
fin = S;
for k=1:50
%tmp(2:(nx+1),2:(ny+1))=readbin(fin,[nx ny],1,'real*4',k-1);
tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
tmp(1,:)=tmp(2,:);
tmp(nx+2,:)=tmp(nx+1,:);
tmp(:,1)=tmp(:,2);
tmp(:,ny+2)=tmp(:,ny+1);
tmp2=interp2(y,x',tmp,y2,x2');
tempS(:,:,k)=tmp2;
writebin(fout,tmp2,1,'real*4',k-1)
end

save tempS tempS
