nx=210; ny=192; nx2=420; ny2=384;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);

% build diff matrix between interpolated bathy and actual 9km bathy:
% true points are new points in bathy and not in the interpolated
tmp=zeros(nx+2,ny+2);
tempS36=zeros(nx2,ny2,50);
tempT36=zeros(nx2,ny2,50);

for i = 1:2
    % set up file output and 
    if i == 1
  var = 'T' ;      
    else
      var = 'S' ;
    end
    
%finit = readbin(finitname,[nx,ny,50]) ;
finit = ncread('spinup36km.nc',var) ;
    
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
  fout=['THETA_840x768_from36km'];
finit = tempT36 ;
 else
   fout=['SALT_840x768_from36km'];
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
