nx=420; ny=384; nx2=840; ny2=768; nz = 50 ;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);

% loading 18km bathy
bathy_interp = zeros(nx2,ny2,50);
bathy18 = ncread('/scratch/general/am8e13/results18km/grid.nc','HFacC') ;
bathy9 = ncread('/scratch/general/am8e13/results9km/grid.nc','HFacC') ;
%bathy18 = ncread('~/grid18km.nc','HFacC') ;
%bathy9 = ncread('~/grid9km.nc','HFacC') ;
fin = bathy18 ;

% interpolate grid to create 9km bathy
for k=1:50
    tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
    tmp(1,:)=tmp(2,:);
    tmp(nx+2,:)=tmp(nx+1,:);
    tmp(:,1)=tmp(:,2);
    tmp(:,ny+2)=tmp(:,ny+1);
    tmp2=interp2(y,x',tmp,y2,x2');
    bathy_interp(:,:,k)=tmp2;
end

% build diff matrix between interpolated bathy and actual 9km bathy:
% true points are new points in bathy and not in the interpolated
diff = (bathy_interp ~= bathy9) ;

% Open files
ncid = netcdf.open( '/hpcdata/scratch/am8e13/arctic420x384/run_tempcorr/toglue/state.nc', 'NOWRITE' );
Ttemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 0 ], [ nx ny nz 20 ] , [ 1 1 1 18] );
Stemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 0 ], [ nx ny nz 20 ] , [ 1 1 1 18]  );
time = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 0 ], [ 20 ] , [ 18 ] );
time/(60*60*24*360)
netcdf.close( ncid );

T = mean(Ttemp,4) ;
S = mean(Stemp,4) ;

fprintf('read \n')
%load('S.mat')
%load('T.mat')

tmp=zeros(nx+2,ny+2);

tempS=zeros(nx2,ny2,50);
tempS_mod=zeros(nx2,ny2,50);
tempS2=zeros(nx2,ny2,50);
tempT=zeros(nx2,ny2,50);
tempT_mod=zeros(nx2,ny2,50);
tempT2=zeros(nx2,ny2,50);

for i = 1:2
    % set up file output and 
    if i == 1
        fout=['THETA_840x768_from18km'];
        fout_mod=['THETA_840x768_from18km_barfill'];
        fout_bathy = ['THETA_840x768_from18km_bathy'];
        finitname = ['/hpcdata/scratch/am8e13/run_template_9km/run_template/WOA05_THETA_JAN_840x768x50_arctic'];
        fin = T ;      
    else
        fout=['SALT_840x768_from18km'];
        fout_mod=['SALT_840x768_from18km_barfill'];
        fout_bathy = ['SALT_840x768_from18km_bathy'];
        finitname = ['/hpcdata/scratch/am8e13/run_template_9km/run_template/WOA05_SALT_JAN_840x768x50_arctic'];
        fin = S ;      
    end
    
    finit = readbin(finitname,[nx2,ny2,50]) ;
    tmp2=zeros(nx+2,ny+2);
    tmp2_mod=zeros(nx+2,ny+2);
    tmp_bathy=zeros(nx+2,ny+2);
        
    for k = 1:50
        % interpolation: create new file interpolating
        tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
        tmp(1,:)=tmp(2,:);
        tmp(nx+2,:)=tmp(nx+1,:);
        tmp(:,1)=tmp(:,2);
        tmp(:,ny+2)=tmp(:,ny+1);
        tmp2=interp2(y,x',tmp,y2,x2');
        tmp2_mod = tmp2 ;
        finit_tmp = finit(:,:,k) ; 
        
        % fill interpolation gap with averages around
        for ix = 1 : nx2
		   for iy = 1 : ny2 
               if tmp2(ix,iy) == 0
                        tmp2_mod(ix,iy) = finit_tmp(ix,iy) ;
               end
           end
        end
        
        tmp3 = tmp2_mod ;
        
        for ix = 1 : nx2
		   for iy = 1 : ny2 
               if ix > 725 
                        tmp2_mod(ix,iy) = finit_tmp(ix,iy) ;
               end
           end
        end
  
        if i == 1
            tempT(:,:,k) = tmp2;
            tempT_mod(:,:,k) = tmp2_mod ;
            tempT2(:,:,k) = tmp3 ;
        else
            tempS(:,:,k) = tmp2;
            tempS_mod(:,:,k) = tmp2_mod ;
            tempS2(:,:,k) = tmp3 ;
        end
    end
    
    if i == 1
        writebin(fout,tempT)
        writebin(fout_mod,tempT_mod)
    else
        writebin(fout,tempS)
        writebin(fout_mod,tempS_mod)
    end
end
        
