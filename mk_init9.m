nx=210; ny=192; nx2=420; ny2=384; nz = 50;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);


%origiT = ncread('spinup36km.nc','T');
%origiS = ncread('spinup36km.nc','S');

ncid = netcdf.open( '/hpcdata/scratch/am8e13/cs_36km_tutorial/run_sponge/results/state.nc', 'NOWRITE' );
Ttemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 720 ], [ nx ny nz 20 ] , [ 1 1 1 18] );
Stemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 720 ], [ nx ny nz 20 ] , [ 1 1 1 18]  );
Ttemp(:,:,:,21:40) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 719 ], [ nx ny nz 20 ] , [ 1 1 1 18] );
Stemp(:,:,:,21:40) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 719 ], [ nx ny nz 20 ] , [ 1 1 1 18]  );
Ttemp(:,:,:,41:60) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 703 ], [ nx ny nz 20 ] , [ 1 1 1 18] );
Stemp(:,:,:,41:60) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 703 ], [ nx ny nz 20 ] , [ 1 1 1 18]  );

time0 = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 720 ], [ 20 ] , [ 18 ] );
time1 = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 703 ], [ 20 ] , [ 18 ] );
time2 = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 719 ], [ 20 ] , [ 18 ] );
time0/(60*60*24*360)
time1/(60*60*24*360)
time2/(60*60*24*360)
netcdf.close( ncid );

origiT = mean(Ttemp,4) ;
origiS = mean(Stemp,4) ;

tofillT = origiT ;
tofillS = origiS ;
fillT = tofillT ;
fillS = tofillS ;

% calculate the average around every 0 point  
for k = 1 : 100
    for iz = 1:nz
        for ix = 2:nx-1
            for iy = 2:ny-1
                if tofillS(ix,iy,iz) == 0                    
                    if (8 - sum([tofillS(ix+1,iy+1,iz), ...
                            tofillS(ix+1,iy,iz)    ,   tofillS(ix,iy+1,iz), ...
                            tofillS(ix-1,iy-1,iz)  ,   tofillS(ix-1,iy,iz), ...
                            tofillS(ix,iy-1,iz)    ,   tofillS(ix+1,iy-1,iz), ...
                            tofillS(ix-1,iy+1,iz)]==  0) ) ~= 0

                        fillS(ix,iy,iz) = (tofillS(ix+1,iy+1,iz) + ...
                            tofillS(ix+1,iy,iz)    +   tofillS(ix,iy+1,iz) + ...
                            tofillS(ix-1,iy-1,iz)  +   tofillS(ix-1,iy,iz) + ...
                            tofillS(ix,iy-1,iz)    +   tofillS(ix+1,iy-1,iz) + ...
                            tofillS(ix-1,iy+1,iz))    /  (8 - sum([tofillS(ix+1,iy+1,iz), ...
                            tofillS(ix+1,iy,iz)    ,   tofillS(ix,iy+1,iz), ...
                            tofillS(ix-1,iy-1,iz)  ,   tofillS(ix-1,iy,iz), ...
                            tofillS(ix,iy-1,iz)    ,   tofillS(ix+1,iy-1,iz), ...
                            tofillS(ix-1,iy+1,iz)]==  0) ) ;
                    end  
                end

                if (8 - sum([tofillT(ix+1,iy+1,iz), ...
                    tofillT(ix+1,iy,iz)    ,   tofillT(ix,iy+1,iz), ...
                    tofillT(ix-1,iy-1,iz)  ,   tofillT(ix-1,iy,iz), ...
                    tofillT(ix,iy-1,iz)    ,   tofillT(ix+1,iy-1,iz), ...
                    tofillT(ix-1,iy+1,iz)]==  0)) ~= 0

                    if tofillT(ix,iy,iz) == 0
                        fillT(ix,iy,iz) = (tofillT(ix+1,iy+1,iz) + ...
                            tofillT(ix+1,iy,iz)    +   tofillT(ix,iy+1,iz) + ...
                            tofillT(ix-1,iy-1,iz)  +   tofillT(ix-1,iy,iz) + ...
                            tofillT(ix,iy-1,iz)    +   tofillT(ix+1,iy-1,iz) + ...
                            tofillT(ix-1,iy+1,iz))    /  (8 - sum([tofillT(ix+1,iy+1,iz), ...
                            tofillT(ix+1,iy,iz)    ,   tofillT(ix,iy+1,iz), ...
                            tofillT(ix-1,iy-1,iz)  ,   tofillT(ix-1,iy,iz), ...
                            tofillT(ix,iy-1,iz)    ,   tofillT(ix+1,iy-1,iz), ...
                            tofillT(ix-1,iy+1,iz)]==  0)) ;
                    end
                end
            end
        end
    end
    tofillS = fillS ;
    tofillT = fillT ;
    fprintf('%f \n',k)
end

tmp=zeros(nx+2,ny+2);
tempS36=zeros(nx2,ny2,50);
tempT36=zeros(nx2,ny2,50);

for i = 1:2
    % set up file output and 
    if i == 1
        finit = fillT ;      
    else
        finit = fillS ;
    end

    %finit = readbin(finitname,[nx,ny,50]) ;
    %finit = ncread('spinup36km.nc',var) ;

    for k = 1:50
        tmp(2:(nx+1),2:(ny+1))=finit(:,:,k);
        tmp(1,:)=tmp(2,:);
        tmp(nx+2,:)=tmp(nx+1,:);
        tmp(:,1)=tmp(:,2);
        tmp(:,ny+2)=tmp(:,ny+1);
        tmp2=interp2(y,x',tmp,y2,x2');
        % fill interpolation gap with averages around
        if i == 1
            tempT36(:,:,k) = tmp2;
        else
            tempS36(:,:,k) = tmp2;
        end
    end
end

nx=420; ny=384; nx2=840; ny2=768;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);

% build diff matrix between interpolated bathy and actual 9km bathy:
% true points are new points in bathy and not in the interpolated
tmp=zeros(nx+2,ny+2);
tempS=zeros(nx2,ny2,50);
tempT=zeros(nx2,ny2,50);

for i = 1:2
    % set up file output and 
    if i == 1
        fout=['THETA_840x768_from36km_fill1'];
        finit = tempT36 ;
    else
        fout=['SALT_840x768_from36km_fill1'];
    finit = tempS36;
    end

    for k = 1:50
        tmp(2:(nx+1),2:(ny+1))=finit(:,:,k);
        tmp(1,:)=tmp(2,:);
        tmp(nx+2,:)=tmp(nx+1,:);
        tmp(:,1)=tmp(:,2);
        tmp(:,ny+2)=tmp(:,ny+1);
        tmp2=interp2(y,x',tmp,y2,x2');
        % fill interpolation gap with averages around
        if i == 1
            tempT(:,:,k) = tmp2;
        else
            tempS(:,:,k) = tmp2;
        end
    end

    if i == 1
        writebin(fout,tempT)
    else
        writebin(fout,tempS)
    end
end
