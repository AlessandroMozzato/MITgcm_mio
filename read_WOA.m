% This script reads woa data and creates climatologies for 36km,18km,9km
accuracy = 'real*4' ;

fprintf('Reading WOA data \n')
month = {'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'} ;
var = {'THETA','SALT'} ;
for v = 1 : 2
    nx=420; ny=384; nx2=840; ny2=768; nz = 50;
    x=-.5:(nx+.5); y=-.5:(ny+.5);
    x2=.25:.5:nx; y2=.25:.5:ny;
    tmp=zeros(nx+2,ny+2);
    
    data = zeros(nx,ny,nz) ;
    for j = 1 : 12
        path = '/scratch/general/am8e13/WOA/' ;
        file_name_complete = strcat(path,'WOA05_',num2str(var{v}),'_',num2str(month{j}),'_420x384x50_arctic');
        fid = fopen( file_name_complete, 'r', 'b' );   
        % Read in the data.  
        fprintf('read %s \n',file_name_complete)
        tmp2 = fread( fid, accuracy );   
        data = data + reshape(tmp2,nx,ny,nz) ;
        fclose(fid);
    end
    
    data = data/12 ;
    
    fprintf('Read %s \n',var{v})
    
    file_name_complete = strcat(path,'WOA05_',num2str(var{v}),'_420x384x50_arctic') ;
    [fid] = fopen( file_name_complete, 'w', 'b' );
    fwrite(fid,data,accuracy);
    fclose(fid);
    
    data9 = zeros(nx2,ny2,nz) ;
    
    for k = 1:50
        tmp(2:(nx+1),2:(ny+1))=data(:,:,k);
        tmp(1,:)=tmp(2,:);
        tmp(nx+2,:)=tmp(nx+1,:);
        tmp(:,1)=tmp(:,2);
        tmp(:,ny+2)=tmp(:,ny+1);
        data9(:,:,k)=interp2(y,x',tmp,y2,x2');
    end
    
    file_name_complete = strcat(path,'WOA05_',num2str(var{v}),'_840x768x50_arctic') ;
    [fid] = fopen( file_name_complete, 'w', 'b' );
    fwrite(fid,data9,accuracy);
    fclose(fid);
    
    
    nx=420; ny=384; nx2=nx/2; ny2=ny/2;
    data36 = zeros(nx2,ny2,nz) ;
    for k = 1:50
        for i=1:nx2
            for j=1:ny2
                ix=((i-1)*2+1):(i*2);
                iy=((j-1)*2+1):(j*2);
                data36(i,j,k)=mean(mean(data(ix,iy,k)));
            end
        end
    end
    
    file_name_complete = strcat(path,'WOA05_',num2str(var{v}),'_210x192x50_arctic') ;
    [fid] = fopen( file_name_complete, 'w', 'b' );
    fwrite(fid,data36,accuracy);
    fclose(fid);
end
