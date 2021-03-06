% This script reads variables and produces initial conditions 
% In particular salt conditions will be changed in order to create a heavy
% and big mass of muddy water in the storegga mud pond

%cd /scratch/general/am8e13/results36km/

hfacw = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacS') ;
grid = hfacw(:,1:192,1);
ieee='b';
prec='real*4';

% Salt is used to create muddy water mass in the storegga mud pond
tempS = ncread('/hpcdata/scratch/am8e13/cs_36km_tutorial/run_perturbation1/results/state.nc','S');
initS = mean(tempS(:,:,:,1:6),4);
%clear tempS
%I = find(~initS);
fprintf('Ive read salt init');


restSMask = zeros(size(initS));
restSMask(34:42,67:83,36:44) = 0.5;
restSMask(35:41,68:82,37:43) = 0.8;
restSMask(36:40,69:81,36:42) = 1 ;

restSValues = ones(size(initS))*35 ;

restSValues(34:42,67:83,36:44) = 50;
restSValues(35:41,68:82,37:43) = 70;
restSValues(36:40,69:81,36:42) = 100;



%tempS = ncread('/scratch/general/am8e13/results2_multitrac18km/state.nc','S');
%initS = tempS(:,:,:,end);
%clear tempS

%restSValues18km = zeros(size(restSMask18km));
%restSValues18km = 35 ;
%restSMask18km = zeros(size(initS));
%for i = 1:420
%    for k = 1:384
%        if grid(i,k)==0
%            restSValues18km(i,k,:)=0;
%            restSMask18km(i,k,:)=2;
%        elseif grid(i,k)==1
%            restSValues18km(i,k,:) = 35 ;
%            restSMask18km(i,k,:)=0;
%        end
%    end
%end


%restSMask18km(34*2:42*2,67*2:83*2,36:44) = 0.5;
%restSMask18km(34*2+1:42*2-1,67*2+1:83*2-1,36:44) = 0.65;
%restSMask18km(35*2:41*2,68*2:82*2,37:43) = 0.8;
%restSMask18km(35*2+1:41*2-1,68*2+1:82*2-1,37:43) = 0.9;
%restSMask18km(36*2:40*2,69*2:81*2,36:42) = 1 ;


%restSValuesk18km(34*2:42*2,67*2:83*2,36:44) = 50;
%restSValues18km(34*2+1:42*2-1,67*2+1:83*2-1,36:44) = 65;
%restSValues18km(35*2:41*2,68*2:82*2,37:43) = 80;
%restSValues18km(35*2+1:41*2-1,68*2+1:82*2-1,37:43) = 90;
%restSValues18km(36*2:40*2,69*2:81*2,36:42) = 100 ;

%subplot(1,2,1)
%imagesc(squeeze(restSValues18km(1:150,1:200,37))); colorbar; title('Perturbed salinity')
%subplot(1,2,2)
%imagesc(squeeze(restSMask18km(1:150,1:200,37))); colorbar; title('Restoring mask')
%averageS = mean(tempS,4) ;

% cd /hpcdata/scratch/am8e13/cs_36km_tutorial/run_exprest/results/
% 
% pertS = ncread('state.nc','S');
% finalPert = pertS(:,:,:,end);
% 
% diffS = finalPert - averageS ;
 restSMask = zeros(size(initS)) ;
 restSMask(:,:,30:50) = 1 ;
% %diffMask(:,:,:) = 0 ;
 restSValues = initS ;

fprintf('Ive created the masks');

%for i = 1:9
%restSMask(:,:,:,i) = diffMask ;
%restSValues(:,:,:,i) = diffSvalue ;
%end

% initS(35-4:45-1,67-4:81-1,35-4:48-1) = 33.5327 + sin(1/ntp*pi/2)*100 ;
% initS(35-3:45-2,67-3:81-2,35-3:48-2) = 33.5327 + sin(2/ntp*pi/2)*100 ;
% initS(35-2:45-3,67-2:81-3,35-2:48-3) = 33.5327 + sin(3/ntp*pi/2)*100 ;
% initS(35-1:45-4,67-1:81-4,35-1:48-4) = 33.5327 + sin(4/ntp*pi/2)*100 ;
% initS(35-0:45-5,67-0:81-5,35-0:48-0) = 33.5327 + sin(5/ntp*pi/2)*100 ;

%tau(35-4:45-1,67-4:81-1,35-4:48-1) = sin(1/ntp*pi/2)*100 
%tau(35-3:45-2,67-3:81-2,35-3:48-2) = sin(2/ntp*pi/2)*100
%tau(35-2:45-3,67-2:81-3,35-2:48-3) = sin(3/ntp*pi/2)*100
%tau(35-1:45-4,67-1:81-4,35-1:48-4) = sin(4/ntp*pi/2)*100
%tau(35-0:45-5,67-0:81-5,35-0:48-5) = sin(5/ntp*pi/2)*100

%for i = 1 : ntp
%initS(35-ntp+i:45-i,67-ntp+i:81-i,35-ntp+i:48-i) = 33.5327 + sin(i/ntp*pi/2)*100 ;
%initS(35-ntp+i:45-i,72,38) = 33.5327 + sin(i/ntp*pi/2)*100 
%tau(i) = sin(i/ntp*pi/2)*100;
%35-ntp+i
%45-i
%initS(30:45,67:81,35:48) = 33.5327 + sin(1/5*pi/2) ;
%end
%initS(35:40,72:76,40:43) = 100 ;
%initS()


% tempT = ncread('state.nc','Temp');
% initT = tempT(:,:,:,end);
% clear tempT
% 
% tempV = ncread('state.nc','V');
% initV = tempV(:,:,:,end);
% clear tempV
% 
% tempU = ncread('state.nc','U');
% initU = tempU(:,:,:,end);
% clear tempU
% 
% tempEta = ncread('state.nc','U');
% initEta = tempEta(:,:,:,end);
% clear tempEta
% 
%
% 
% fid=fopen('initT','w',ieee); 
% fwrite(fid,initT,prec); 
% fclose(fid);
% 
% fid=fopen('initV','w',ieee); 
% fwrite(fid,initV,prec); 
% fclose(fid);
% 
% fid=fopen('initU','w',ieee); 
% fwrite(fid,initU,prec); 
% fclose(fid);
% 
% fid=fopen('initEta','w',ieee); 
% fwrite(fid,initEta,prec); 
% fclose(fid);
%  
 cd ~/MITgcm_mio/
% fid=fopen('initS','w',ieee); 
% fwrite(fid,initS,prec); 
% fclose(fid);

 fid=fopen('restSMask_norm_e','w',ieee); 
 fwrite(fid,restSMask,prec); 
 fclose(fid);
% 
 fid=fopen('restSValues_norm_new','w',ieee); 
 fwrite(fid,restSValues,prec); 
 fclose(fid);

% fid=fopen('restSMask18km','w',ieee); 
% fwrite(fid,restSMask18km,prec); 
% fclose(fid);
% % 
% fid=fopen('restSValues_100_18km','w',ieee); 
% fwrite(fid,restSValues18m,prec); 
% fclose(fid);

cd ~/MITgcm_mio/
