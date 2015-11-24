cd /skylla/arctic/run_template_9km/
nx=420; ny=384; nx2=840; ny2=768;
x=-.5:(nx+.5); y=-.5:(ny+.5);
x2=.25:.5:nx; y2=.25:.5:ny;
tmp=zeros(nx+2,ny+2);
for fld={'THETA','SALT'}
  fin=['../run_template_cube81/WOA05_' fld{1} '_JAN_420x384x50_arctic'];
  fout=['WOA05_' fld{1} '_JAN_840x768x50_arctic'];
  for k=1:50
    tmp(2:(nx+1),2:(ny+1))=readbin(fin,[nx ny],1,'real*4',k-1);
    tmp(1,:)=tmp(2,:);
    tmp(nx+2,:)=tmp(nx+1,:);
    tmp(:,1)=tmp(:,2);
    tmp(:,ny+2)=tmp(:,ny+1);
    tmp2=interp2(y,x',tmp,y2,x2');
    figure(1), clf, mypcolor(tmp'); thincolorbar, title(k)
    figure(2), clf, mypcolor(tmp2'); thincolorbar, title(k)
    pause(.01)
    writebin(fout,tmp2,1,'real*4',k-1)
  end
end
for fld={'HSNOW','HSALT','HEFF','AREA'}
  fin=['../run_template_cube81/' fld{1} '_420x384_arctic.cube81'];
  fout=[fld{1} '_840x768_arctic.cube81'];
  tmp(2:(nx+1),2:(ny+1))=readbin(fin,[nx ny]);
  tmp(1,:)=tmp(2,:);
  tmp(nx+2,:)=tmp(nx+1,:);
  tmp(:,1)=tmp(:,2);
  tmp(:,ny+2)=tmp(:,ny+1);
  tmp2=interp2(y,x',tmp,y2,x2');
  figure(1), clf, mypcolor(tmp'); thincolorbar
  figure(2), clf, mypcolor(tmp2'); thincolorbar
  pause(.01)
  writebin(fout,tmp2)
end
