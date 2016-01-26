nx=420; ny=384; nx2=840; ny2=768; nz = 50 ;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);

% build diff matrix between interpolated bathy and actual 9km bathy:
% true points are new points in bathy and not in the interpolated


<<<<<<< HEAD
% Open files temp/salt
ncid = netcdf.open( '/hpcdata/scratch/am8e13/arctic420x384/run_tempcorr/toglue/state.nc', 'NOWRITE' );
Ttemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 0 ], [ nx ny nz 10 ] , [ 1 1 1 18] );
Stemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 0 ], [ nx ny nz 10 ] , [ 1 1 1 18]  );
%Ttemp(:,:,:,11:20) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 1 ], [ nx ny nz 10 ] , [ 1 1 1 18] );
%Stemp(:,:,:,11:20) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 1 ], [ nx ny nz 10 ] , [ 1 1 1 18]  );
%Ttemp(:,:,:,21:30) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 17 ], [ nx ny nz 10 ] , [ 1 1 1 18] );
%Stemp(:,:,:,21:30) = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 17 ], [ nx ny nz 10 ] , [ 1 1 1 18]  );
time = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 0 ], [ 10 ] , [ 18 ] );
netcdf.close( ncid );
T = mean(Ttemp,4) ;
S = mean(Stemp,4) ;

% Open files seaice
ncid = netcdf.open( '/hpcdata/scratch/am8e13/arctic420x384/run_tempcorr/toglue/SEAICE.nc', 'NOWRITE' );
time = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 0 ] , [ 10 ] );
time/(60*60*24*360)
Area = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'SIarea' ), [ 0 0 0 0 ] , [ nx ny 1 1 ] , [ 1 1 1 1 ]  );
Heff = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'SIheff' ), [ 0 0 0 0 ] , [ nx ny 1 1 ] , [ 1 1 1 1 ]  );
Hsnow = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'SIhsnow' ), [ 0 0 0 0 ] , [ nx ny 1 1 ] , [ 1 1 1 1 ] );
Hsalt = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'SIhsalt' ), [ 0 0 0 0 ] , [ nx ny 1 1 ] , [ 1 1 1 1 ] );


netcdf.close( ncid );
T = mean(Ttemp,4) ;
S = mean(Stemp,4) ;


=======
% Open files
ncid = netcdf.open( '/hpcdata/scratch/am8e13/arctic420x384/run_tempcorr/toglue/state.nc', 'NOWRITE' );
Ttemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'Temp' ), [ 0 0 0 0 ], [ nx ny nz 10 ] , [ 1 1 1 18] );
Stemp = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 0 ], [ nx ny nz 10 ] , [ 1 1 1 18]  );
time = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 0 ], [ 10 ] , [ 18 ] );
time/(60*60*24*360)
netcdf.close( ncid );

T = mean(Ttemp,4) ;
S = mean(Stemp,4) ;

>>>>>>> 9c43d859eb9656583e475b30296956c2fe428802
fprintf('read \n')

tmp=zeros(nx+2,ny+2);

tempS=zeros(nx2,ny2,50);
tempS_mod=zeros(nx2,ny2,50);
tempT=zeros(nx2,ny2,50);
tempT_mod=zeros(nx2,ny2,50);

<<<<<<< HEAD
for i = 1:6
    % set up file output and 
    if i == 1
        fout=['THETA_840x768_from18km'];
        fin = T ;
    elseif i == 2
        fout=['SALT_840x768_from18km'];
        fin = S ;
    elseif i == 3
        fout=['Heff_840x768_from18km'];
        fin = Heff ;
    elseif i == 4
        fout=['Hsalt_840x768_from18km'];
        fin = Hsalt ;
    elseif i == 5
        fout=['Hsnow_840x768_from18km'];
        fin = Hsnow ;
    elseif i == 6
        fout=['Area_840x768_from18km'];
        fin = Area ;
    end
    
    tmp2=zeros(nx+2,ny+2);
    
    if i == 1 || i == 2
        tmptot2 = zeros(nx2,ny2,50) ;
        for k = 1:50
            % interpolation: create new file interpolating    
            tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
            tmp(1,:)=tmp(2,:);
            tmp(nx+2,:)=tmp(nx+1,:);
            tmp(:,1)=tmp(:,2);
            tmp(:,ny+2)=tmp(:,ny+1);
            tmp2=interp2(y,x',tmp,y2,x2');
            tmptot2(:,:,k) = tmp2;

            % fill interpolation gap with averages around
    %         for jj = 1 : 2 % multiple iteration to fill the spaces
    % 		   for ix = 1 : nx2
    % 			      for iy = 1 : ny2 
    % 					 if isnan(tmp2(ix,iy))
    %                         if ix ~= 1 && iy ~= 1 && ix ~= nx2 && iy ~= ny2 && ix ~= 2 && iy ~= 2 && ix ~= nx2-1 && iy ~= ny2-1 
    %                             % diff  from zero mean it is filling partial cells
    %                             tmp2_mod(ix,iy) = nanmean([...
    % 											    tmp2(ix+1,iy),tmp2(ix-1,iy),tmp2(ix,iy-1),tmp2(ix,iy+1),...
    % 												tmp2(ix+1,iy+1),tmp2(ix-1,iy-1),tmp2(ix+1,iy-1),tmp2(ix-1,iy+1)
    % 								    ]) ;
    %                         end
    %                     end
    %                 end
    %           end
    % 		tmp2 = tmp2_mod ;
    %         fprintf('Iter n: %f , nans: %f \n',jj, sum(sum(isnan(tmp2))))
    %         end

        end
    elseif i == 3 || i == 4 || i == 5 || i == 6
        tmptot2 = zeros(nx2,ny2) ;
        tmp(2:(nx+1),2:(ny+1))=fin(:,:);
=======
for i = 1:2
    % set up file output and 
    if i == 1
        fout=['THETA_840x768_from18km'];
        fout_mod=['THETA_840x768_from18km_mod3'];
        fin = T ;
    else
        fout=['SALT_840x768_from18km'];
        fout_mod=['SALT_840x768_from18km_mod3'];
        fin = S ;      
    end
    
    tmp2=zeros(nx+2,ny+2);
    tmp2_mod=zeros(nx+2,ny+2);
        
    for k = 1:50
        % interpolation: create new file interpolating
        tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
>>>>>>> 9c43d859eb9656583e475b30296956c2fe428802
        tmp(1,:)=tmp(2,:);
        tmp(nx+2,:)=tmp(nx+1,:);
        tmp(:,1)=tmp(:,2);
        tmp(:,ny+2)=tmp(:,ny+1);
        tmp2=interp2(y,x',tmp,y2,x2');
<<<<<<< HEAD
        tmptot2 = tmp2 ;
    end
    
    fprintf('Write: %s \n',fout)
    writebin(fout,tmptot2)
=======
        tmp2_mod = tmp2 ;
        tmp2(tmp2==0) = nan ;
        tmp2_mod(tmp2_mod==0) = nan ;
        
        if i == 1
            tempT(:,:,k) = tmp2;
        else
            tempS(:,:,k) = tmp2;
        end
        
        % fill interpolation gap with averages around
        for jj = 1 : 2 % multiple iteration to fill the spaces
		   for ix = 1 : nx2
			      for iy = 1 : ny2 
					 if isnan(tmp2(ix,iy))
                        if ix ~= 1 && iy ~= 1 && ix ~= nx2 && iy ~= ny2 && ix ~= 2 && iy ~= 2 && ix ~= nx2-1 && iy ~= ny2-1 
                            % diff  from zero mean it is filling partial cells
                            tmp2_mod(ix,iy) = nanmean([...
											    tmp2(ix+1,iy),tmp2(ix-1,iy),tmp2(ix,iy-1),tmp2(ix,iy+1),...
												tmp2(ix+1,iy+1),tmp2(ix-1,iy-1),tmp2(ix+1,iy-1),tmp2(ix-1,iy+1)
								    ]) ;
                        end
                    end
                end
           end
		tmp2 = tmp2_mod ;
        fprintf('Iter n: %f , nans: %f \n',jj, sum(sum(isnan(tmp2))))
        end
        
        if i == 1
            tempT_mod(:,:,k) = tmp2_mod ;
        else
            tempS_mod(:,:,k) = tmp2_mod ;
        end
    end
    
	tempT(isnan(tempT)) = 0;
    tempS(isnan(tempS)) = 0;
    tempT_mod(isnan(tempT_mod)) = 0;
    tempS_mod(isnan(tempS_mod)) = 0;
    
    if i == 1
        writebin(fout,tempT)
        writebin(fout_mod,tempT_mod)
    else
        writebin(fout,tempS)
        writebin(fout_mod,tempS_mod)
    end
>>>>>>> 9c43d859eb9656583e475b30296956c2fe428802
end
        
