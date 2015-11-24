%%% This script produces masks and values for the perturbation experiment
%%% Different resolutions can be used

res = 36 ; % resolution can be 36,18 and 9

if res == 36
    k = 1 ; 
    hfacc = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ;
elseif res == 18
    k = 2 ;
    hfacc = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ;
elseif res == 9
    k = 3 ;
    hfacc = ncread('/scratch/general/am8e13/results36km/grid.nc','HFacC') ;
else
    printf('Resolution error')
end

ieee='b';
prec='real*4';


fprintf('Ive read salt init \n');

if res == 36
    
    %tempS = ncread('/hpcdata/scratch/am8e13/cs_36km_tutorial/run_perturbation1/results/state.nc','S',[1 1 1 1],[210 192 50 10]);
    %initS = mean(tempS(:,:,:,1:6),4);
    
    restSMask = zeros(210,192,50);
    restSMask(34:42,67:83,36:44) = 0.5;
    restSMask(35:41,68:82,37:43) = 0.8;
    restSMask(36:40,69:81,36:42) = 1 ;

    restSValues = ones(210,192,50) ;
    restSValues(34:42,67:83,36:44) = 50;
    restSValues(35:41,68:82,37:43) = 70;
    restSValues(36:40,69:81,36:42) = 100;
    
%     % Restoring Mask
%     restSMask_rest = zeros(size(initS)) ;
%     restSMask_rest(:,:,30:50) = 1 ;
%     % Restoring Values
%     restSValues_rest = initS ;
    
    fid=fopen(strcat('/noc/users/am8e13/pertSMask_',num2str(res)),'w',ieee); 
    fwrite(fid,restSMask,prec); 
    fclose(fid);
     
    fid=fopen(strcat('/noc/users/am8e13/pertSValue_',num2str(res)),'w',ieee); 
    fwrite(fid,restSValues,prec); 
    fclose(fid);
    
%     fid=fopen(strcat('/noc/users/am8e13/restSMask_',num2str(res)),'w',ieee); 
%     fwrite(fid,restSMask_rest,prec); 
%     fclose(fid);
%      
%     fid=fopen(strcat('/noc/users/am8e13/restSValues_',num2str(res)),'w',ieee); 
%     fwrite(fid,restSValues_rest,prec); 
%     fclose(fid);
%     
elseif res == 18
        
    %tempS = ncread('/hpcdata/scratch/am8e13/arctic420x384/run_tempcorr/results/state.nc','S',[1 1 1 1],[420 384 50 6]);
    %initS = mean(tempS(:,:,:,1:6),4);

    restSMask = zeros(420,384,50);
    restSMask(68:84,134:166,36:44) = 0.5;
    restSMask(69:83,135:165,36:44) = 0.65;
    restSMask(70:82,136:164,37:43) = 0.8;
    restSMask(71:81,137:163,37:43) = 0.9;
    restSMask(72:80,138:162,36:42) = 1 ;

    restSValues = ones(420,384,50)*35 ;
    restSValues(68:84,134:166,36:44) = 50;
    restSValues(69:83,135:165,36:44) = 62;
    restSValues(70:82,136:164,37:43) = 75;
    restSValues(71:81,137:163,37:43) = 87;
    restSValues(72:80,138:162,36:42) = 100 ;

%     % Restoring Mask
%     restSMask_rest = zeros(size(initS)) ;
%     restSMask_rest(:,:,30:50) = 1 ;
%     % Restoring Values
%     restSValues_rest = initS ;
    
    fid=fopen(strcat('/noc/users/am8e13/pertSMask_',num2str(res)),'w',ieee); 
    fwrite(fid,restSMask,prec); 
    fclose(fid);
     
    fid=fopen(strcat('/noc/users/am8e13/pertSValue_',num2str(res)),'w',ieee); 
    fwrite(fid,restSValues,prec); 
    fclose(fid);
    
%     fid=fopen(strcat('/noc/users/am8e13/restSMask_',num2str(res)),'w',ieee); 
%     fwrite(fid,restSMask_rest,prec); 
%     fclose(fid);
%      
%     fid=fopen(strcat('/noc/users/am8e13/restSValues_',num2str(res)),'w',ieee); 
%     fwrite(fid,restSValues_rest,prec); 
%     fclose(fid);
    
elseif res == 9
        
    %tempS = ncread('/hpcdata/scratch/am8e13/run_template_9km/run_tempcorr/results/state.nc','S',[1 1 1 1],[840 768 50 10]);
    %initS = mean(tempS(:,:,:,1:6),4);
    
    restSMask = zeros(840,768,50);
    restSMask(136:168,268:332,36:44) = 0.5;
    restSMask(137:167,269:331,36:44) = 0.57;
    restSMask(138:166,270:330,36:44) = 0.65;
    restSMask(139:167,271:329,36:44) = 0.71;
    restSMask(140:164,272:328,37:43) = 0.8;
    restSMask(141:163,273:327,37:43) = 0.86;
    restSMask(142:162,274:326,37:43) = 0.91;
    restSMask(143:161,275:325,37:43) = 0.96;
    restSMask(144:160,276:324,36:42) = 1 ;

    restSValues = ones(840,768,50)*35 ;
    restSValues(136:168,268:332,36:44) = 5;
    restSValues(137:167,269:331,36:44) = 57;
    restSValues(138:166,270:330,36:44) = 65;
    restSValues(139:167,271:329,36:44) = 71;
    restSValues(140:164,272:328,37:43) = 8;
    restSValues(141:163,273:327,37:43) = 86;
    restSValues(142:162,274:326,37:43) = 91;
    restSValues(143:161,275:325,37:43) = 96;
    restSValues(144:160,276:324,36:42) = 100 ;
    
%     % Restoring Mask
%     restSMask_rest = zeros(size(initS)) ;
%     restSMask_rest(:,:,30:50) = 1 ;
%     % Restoring Values
%     restSValues_rest = initS ;

    fid=fopen(strcat('/noc/users/am8e13/pertSMask_',num2str(res)),'w',ieee); 
    fwrite(fid,restSMask,prec); 
    fclose(fid);
     
    fid=fopen(strcat('/noc/users/am8e13/pertSValue_',num2str(res)),'w',ieee); 
    fwrite(fid,restSValues,prec); 
    fclose(fid);
    
%     fid=fopen(strcat('/noc/users/am8e13/restSMask_',num2str(res)),'w',ieee); 
%     fwrite(fid,restSMask_rest,prec); 
%     fclose(fid);
%      
%     fid=fopen(strcat('/noc/users/am8e13/restSValues_',num2str(res)),'w',ieee); 
%     fwrite(fid,restSValues_rest,prec); 
%     fclose(fid);
    
else
    printf('Wrong dimension')
end


