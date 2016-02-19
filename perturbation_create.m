%%% This script produces masks and values for the perturbation experiment
%%% Different resolutions can be used

max_val = 70 ; % maximum value for the perturbation
min_val = 50 ; % minumum value for the perturbation

res = 36 ; % resolution can be 36,18 and 9

ieee='b';
prec='real*4';

if res == 36
    nx = 210 ; ny = 192 ; nz = 50 ; nt = 24 ;
    ncid = netcdf.open( '/hpcdata/scratch/am8e13/cs_36km_tutorial/experiments/statevalue.nc', 'NOWRITE' );
    Save = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'S' ), [ 0 0 0 0 ], [ nx ny nz nt ] , [ 1 1 1 1 ] );
    netcdf.close( ncid );
    
    mask = linspace(0.5,1,3) ;
    restSMask = zeros(210,192,50);
    restSMask(34:42,67:83,36:44) = mask(1) ;
    restSMask(35:41,68:82,37:43) = mask(2) ;
    restSMask(36:40,69:81,36:42) = mask(3) ;

    value = linspace(min_val,max_val,3) ;
    restSValues = ones(210,192,50)*35 ;
    restSValues(34:42,67:83,36:44) = value(1) ;
    restSValues(35:41,68:82,37:43) = value(2) ;
    restSValues(36:40,69:81,36:42) = value(3) ;
    
    restSMask_rest = zeros(210,192,50);
    restSMask_rest(:,:,30:50) = 1 ;
    
    restSValues_rest = mean(Save,4) ;
    
    writebin(strcat('/scratch/general/am8e13/perturbation_fields/restSMask_',num2str(res),'km'),restSMask_rest)
    writebin(strcat('/scratch/general/am8e13/perturbation_fields/restSValue_',num2str(res),'km_',num2str(max_val)),restSValues_rest)
    
    writebin(strcat('/scratch/general/am8e13/perturbation_fields/pertSMask_',num2str(res),'km'),restSMask)
    
%     fid=fopen(strcat('/scratch/general/am8e13/perturbation_fields/pertSMask_',num2str(res),'km'),'w',ieee); 
%     fwrite(fid,restSMask,prec); 
%     fclose(fid);
    
    writebin(strcat('/scratch/general/am8e13/perturbation_fields/pertSValue_',num2str(res),'km_',num2str(max_val)),restSValues)
     
%     fid=fopen(strcat('/scratch/general/am8e13/perturbation_fields/pertSValue_',num2str(res),'km_',num2str(max_val)),'w',ieee);   
%     fwrite(fid,restSValues,prec); 
%     fclose(fid);
    
elseif res == 18
    mask = linspace(0.5,1,5) ;
    restSMask = zeros(420,384,50);
    restSMask(68:84,134:166,36:44) = mask(1) ;
    restSMask(69:83,135:165,36:44) = mask(2) ;
    restSMask(70:82,136:164,37:43) = mask(3) ;
    restSMask(71:81,137:163,37:43) = mask(4) ;
    restSMask(72:80,138:162,36:42) = mask(5) ;

    value = linspace(min_val,max_val,5) ;
    restSValues = ones(420,384,50)*35 ;
    restSValues(68:84,134:166,36:44) = value(1) ;
    restSValues(69:83,135:165,36:44) = value(2) ;
    restSValues(70:82,136:164,37:43) = value(3) ;
    restSValues(71:81,137:163,37:43) = value(4) ; 
    restSValues(72:80,138:162,36:42) = value(5) ;
    
    writebin(strcat('/scratch/general/am8e13/perturbation_fields/pertSMask_',num2str(res),'km'),restSMask)
    
%     fid=fopen(strcat('/scratch/general/am8e13/perturbation_fields/pertSMask_',num2str(res),'km'),'w',ieee); 
%     fwrite(fid,restSMask,prec); 
%     fclose(fid);
    
    writebin(strcat('/scratch/general/am8e13/perturbation_fields/pertSValue_',num2str(res),'km_',num2str(max_val)),restSValues)
     
%     fid=fopen(strcat('/scratch/general/am8e13/perturbation_fields/pertSValue_',num2str(res),'km_',num2str(max_val)),'w',ieee);   
%     fwrite(fid,restSValues,prec); 
%     fclose(fid);

elseif res == 9
    mask = linspace(0.5,1,9) ;
    restSMask = zeros(840,768,50) ;
    restSMask(136:168,268:332,36:44) = mask(1) ;
    restSMask(137:167,269:331,36:44) = mask(2) ;
    restSMask(138:166,270:330,36:44) = mask(3) ;
    restSMask(139:167,271:329,36:44) = mask(4) ;
    restSMask(140:164,272:328,37:43) = mask(5) ;
    restSMask(141:163,273:327,37:43) = mask(6) ;
    restSMask(142:162,274:326,37:43) = mask(7) ;
    restSMask(143:161,275:325,37:43) = mask(8) ;
    restSMask(144:160,276:324,36:42) = mask(9) ;

    value = linspace(min_val,max_val,9) ;
    restSValues = ones(840,768,50)*35 ;
    restSValues(136:168,268:332,36:44) = value(1) ;
    restSValues(137:167,269:331,36:44) = value(2) ;
    restSValues(138:166,270:330,36:44) = value(3) ;
    restSValues(139:167,271:329,36:44) = value(4) ;
    restSValues(140:164,272:328,37:43) = value(5) ;
    restSValues(141:163,273:327,37:43) = value(6) ;
    restSValues(142:162,274:326,37:43) = value(7) ;
    restSValues(143:161,275:325,37:43) = value(8) ;
    restSValues(144:160,276:324,36:42) = value(9) ; 

    writebin(strcat('/scratch/general/am8e13/perturbation_fields/pertSMask_',num2str(res),'km'),restSMask)
    
%     fid=fopen(strcat('/scratch/general/am8e13/perturbation_fields/pertSMask_',num2str(res),'km'),'w',ieee); 
%     fwrite(fid,restSMask,prec); 
%     fclose(fid);
    
    writebin(strcat('/scratch/general/am8e13/perturbation_fields/pertSValue_',num2str(res),'km_',num2str(max_val)),restSValues)
     
%     fid=fopen(strcat('/scratch/general/am8e13/perturbation_fields/pertSValue_',num2str(res),'km_',num2str(max_val)),'w',ieee);   
%     fwrite(fid,restSValues,prec); 
%     fclose(fid);
    
end

fprintf('Generated %i km files \n',res)


