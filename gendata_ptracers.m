% This script produces initial tracers files for the 36 and 18km resolution
% simulation

%clear all
%close all

ieee='b';
prec='real*4';

cd tracers/

% Small Mud Pond for 18 e 36 kms

storeggaSmall_36km = zeros(210,192,50);
storeggaSmall_36km(35:40,72:76,40:43) = 100;

fid=fopen('storeggaSmall_36km','w',ieee); 
fwrite(fid,storeggaSmall_36km,prec); 
fclose(fid);

storeggaSmall_18km = zeros(420,384,50);
storeggaSmall_18km(35*2:40*2,72*2:76*2,40:43) = 100;

fid=fopen('storeggaSmall_18km','w',ieee); 
fwrite(fid,storeggaSmall_18km,prec); 
fclose(fid);

% Big mud pond for 18 and 36 km
 
storeggaBig_36km = zeros(210,192,50);
storeggaBig_36km(35:41,68:82,37:43) = 100;

fid=fopen('storeggaBig_36km','w',ieee); 
fwrite(fid,storeggaBig_36km,prec); 
fclose(fid);
 
storeggaBig_18km = zeros(420,384,50);
storeggaBig_18km(35*2:41*2,68*2:82*2,37:43) = 100;

fid=fopen('storeggaBig_18km','w',ieee); 
fwrite(fid,storeggaBig_18km,prec); 
fclose(fid);

% Northern shallow storegga pond

storeggaNorth_36km = zeros(210,192,50);
storeggaNorth_36km(29:34,57:66,15:22) = 100;

fid=fopen('storeggaNorth_36km','w',ieee); 
fwrite(fid,storeggaNorth_36km,prec); 
fclose(fid);

storeggaNorth_18km = zeros(420,384,50);
storeggaNorth_18km(29*2:34*2,57*2:66*2,15:22) = 100;

fid=fopen('storeggaNorth_18km','w',ieee); 
fwrite(fid,storeggaNorth_18km,prec); 
fclose(fid);

% Traenadjupet Tracer

%(36:42,58:61,20:24)

traenadjupet_36km = zeros(210,192,50);
traenadjupet_36km(36:42,58:61,20:24)= 100;

fid=fopen('traenadjupet_36km','w',ieee); 
fwrite(fid,traenadjupet_36km,prec); 
fclose(fid);

traenadjupet_18km = zeros(420,384,50);
traenadjupet_18km(36*2:42*2,58*2:61*2,20:24)= 100;

fid=fopen('traenadjupet_18km','w',ieee); 
fwrite(fid,traenadjupet_18km,prec); 
fclose(fid);

% Bear Island

% New bear island 55:59,54:57,18:22

bearisland_36km = zeros(210,192,50) ;
bearisland_36km(55:59,54:57,18:22)= 100 ;

fid=fopen('bearisland_36km','w',ieee) ; 
fwrite(fid,bearisland_36km,prec); 
fclose(fid);

bearisland_18km = zeros(420,384,50) ;
bearisland_18km(55*2:59*2,54*2:57*2,18:22)= 100 ;

fid=fopen('bearisland_18km','w',ieee); 
fwrite(fid,bearisland_18km,prec); 
fclose(fid);

% Andoya slide

andoya_36km = zeros(210,192,50) ;
andoya_36km(47:50,52:56,20:24)= 100 ;

fid=fopen('andoya_36km','w',ieee) ; 
fwrite(fid,andoya_36km,prec); 
fclose(fid);

andoya_18km = zeros(420,384,50) ;
andoya_18km(47*2:50*2,52*2:56*2,20:24)= 100 ;

fid=fopen('andoya_18km','w',ieee); 
fwrite(fid,andoya_18km,prec); 
fclose(fid);

