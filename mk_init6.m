nx=420; ny=384; nx2=840; ny2=768;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);

% build diff matrix between interpolated bathy and actual 9km bathy:
% true points are new points in bathy and not in the interpolated
tmp=zeros(nx+2,ny+2);
tempS=zeros(nx2,ny2,50);
tempS_mod=zeros(nx2,ny2,50);
tempT=zeros(nx2,ny2,50);
tempT_mod=zeros(nx2,ny2,50);

for i = 1:2
    % set up file output and 
    if i == 1
	  fout=['THETA_840x768_woa'];
finitname = ['WOA05_THETA_JAN_840x768x50_arctic'];        
 else
   fout=['SALT_840x768_woa'];
finitname = ['WOA05_SALT_JAN_840x768x50_arctic'];
    end
    
    finit = readbin(finitname,[nx2,ny2,50]) ;
        
for k = 1:50
        % fill interpolation gap with averages around
        if i == 1
	  tempT(:,:,k) = finit(:,:,k);
        else
	  tempS(:,:,k) = finit(:,:,k);
        end
    end
    
    if i == 1
	  writebin(fout,tempT)
      else
        writebin(fout,tempS)
    end
end
        
