% model grids

grid = rdmnc('grid.*') ;

state = rdmnc('state.*') ;

xc = grid.XC ;
yc = grid.YC ;
% xi = 0 : 0.5 : 20 ;
% yi = 0 : 0.5 : 60 ;

xi=-179:0.5:180;yi=-89:0.5:90;

XG = grid.XG ;
YG = grid.YG ;

del = cube2latlon_preprocess(xc,yc,xi,yi);

[U,V] = uvcube2latlongrid(del,state.U,state.V,XG,YG,grid.RC,grid.dxG,grid.dyG)