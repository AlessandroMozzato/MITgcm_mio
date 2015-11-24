nx=420; ny=384; nx2=840; ny2=768;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);

tempS = zeros(nx2,ny2,50);
tempT = zeros(nx2,ny2,50);
tempS_mod = zeros(nx2,ny2,50);
tempT_mod = zeros(nx2,ny2,50);

load('S.mat')
load('T.mat')
load('bathy.mat')

fout=['THETA_840x768_from18km'];
fout_mod=['THETA_840x768_from18km_mod'];
fin = T ;

temp_bathy = zeros(nx2,ny2,50);
bathy18 = ncread('/scratch/general/am8e13/results18km/grid.nc','HFacC') ;

fin = bathy18 ;

for k=1:50
	tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
tmp(1,:)=tmp(2,:);
tmp(nx+2,:)=tmp(nx+1,:);
tmp(:,1)=tmp(:,2);
tmp(:,ny+2)=tmp(:,ny+1);
tmp2=interp2(y,x',tmp,y2,x2');
temp_bathy(:,:,k)=tmp2;
end

diff = (temp_bathy ~= bathy) ;

for k=1:50
	tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
tmp(1,:)=tmp(2,:);
tmp(nx+2,:)=tmp(nx+1,:);
tmp(:,1)=tmp(:,2);
tmp(:,ny+2)=tmp(:,ny+1);
tmp2=interp2(y,x',tmp,y2,x2');
    
tmp2_mod = tmp2 ;
tmp2(bathy(:,:,k)==0)=nan ;
aveT(k) = nanmean(nanmean(tmp2));
for ix = 1 : nx2
	   for iy = 1 : ny2 
            if diff
		      tmp2_mod(ix,iy) = aveT(k) ;
            end
            
            if ix ~= 1 && iy ~= 1 && ix ~= nx2 && iy ~= ny2 && ix ~= 2 && iy ~= 2 && ix ~= nx2-1 && iy ~= ny2-1 
	      if tmp2(ix,iy) == 0 && bathy(ix,iy,k) == 1
	      tmp2_mod(ix,iy) = nanmean([...
											tmp2(ix+1,iy),tmp2(ix-1,iy),tmp2(ix,iy-1),tmp2(ix,iy+1),...
											    tmp2(ix+1,iy+1),tmp2(ix-1,iy-1),tmp2(ix+1,iy-1),tmp2(ix-1,iy+1),...
											    tmp2(ix+2,iy+2),tmp2(ix+2,iy+1),tmp2(ix+2,iy),tmp2(ix+2,iy-1),tmp2(ix+2,iy-2),...
											    tmp2(ix-2,iy+2),tmp2(ix-2,iy+1),tmp2(ix-2,iy),tmp2(ix-2,iy-1),tmp2(ix-2,iy-2),...
											    tmp2(ix+1,iy+2),tmp2(ix,iy+2),tmp2(ix-1,iy+2),...
											    tmp2(ix-2,iy-1),tmp2(ix-2,iy),tmp2(ix-2,iy+1)
					 ]) ;
                end
            end

        end
    end
    
		tmp2(bathy(:,:,k)==0)=0;
tmp2(isnan(tmp2))=0;
tmp2_mod(bathy(:,:,k)==0)=0;
tmp2_mod(isnan(tmp2_mod))=0;
tempT(:,:,k) = tmp2;
tempT_mod(:,:,k) = tmp2_mod ;
end

writebin(fout,tempT)
writebin(fout_mod,tempT_mod)

fout=['SALT_840x768_from18km'];
fout_mod=['SALT_840x768_from18km_mod'];
fin = S;

for k=1:50
	tmp(2:(nx+1),2:(ny+1))=fin(:,:,k);
tmp(1,:)=tmp(2,:);
tmp(nx+2,:)=tmp(nx+1,:);
tmp(:,1)=tmp(:,2);
tmp(:,ny+2)=tmp(:,ny+1);
tmp2=interp2(y,x',tmp,y2,x2');
    
tmp2_mod = tmp2 ;
tmp2(bathy(:,:,k)==0)=nan ;
aveT(k) = nanmean(nanmean(tmp2));
for ix = 1 : nx2
	   for iy = 1 : ny2 
            if diff
		      tmp2_mod(ix,iy) = aveT(k) ;
            end
            
            if ix ~= 1 && iy ~= 1 && ix ~= nx2 && iy ~= ny2 && ix ~= 2 && iy ~= 2 && ix ~= nx2-1 && iy ~= ny2-1 
	      if tmp2(ix,iy) == 0 && bathy(ix,iy,k) == 1
	      tmp2_mod(ix,iy) = nanmean([...
											tmp2(ix+1,iy),tmp2(ix-1,iy),tmp2(ix,iy-1),tmp2(ix,iy+1),...
											    tmp2(ix+1,iy+1),tmp2(ix-1,iy-1),tmp2(ix+1,iy-1),tmp2(ix-1,iy+1),...
											    tmp2(ix+2,iy+2),tmp2(ix+2,iy+1),tmp2(ix+2,iy),tmp2(ix+2,iy-1),tmp2(ix+2,iy-2),...
											    tmp2(ix-2,iy+2),tmp2(ix-2,iy+1),tmp2(ix-2,iy),tmp2(ix-2,iy-1),tmp2(ix-2,iy-2),...
											    tmp2(ix+1,iy+2),tmp2(ix,iy+2),tmp2(ix-1,iy+2),...
											    tmp2(ix-2,iy-1),tmp2(ix-2,iy),tmp2(ix-2,iy+1)
					 ]) ;
                end
            end

        end
    end
    
		tmp2(bathy(:,:,k)==0)=0;
tmp2(isnan(tmp2))=0;
tmp2_mod(bathy(:,:,k)==0)=0;
tmp2_mod(isnan(tmp2_mod))=0;
tempS(:,:,k) = tmp2;
tempS_mod(:,:,k) = tmp2_mod ;
end

writebin(fout,tempS)
writebin(fout_mod,tempS_mod)


