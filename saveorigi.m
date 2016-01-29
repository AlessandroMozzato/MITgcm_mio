ieee='b';
prec='real*4';    

fid=fopen('/scratch/general/am8e13/originT','w',ieee); 
fwrite(fid,origiT,prec); 
fclose(fid);

fid=fopen('/scratch/general/am8e13/originS','w',ieee); 
fwrite(fid,origiS,prec); 
fclose(fid);