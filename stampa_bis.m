close all
clear all

dyn = rdmnc('dynDiag.*') ;

n = length(dyn.iter) ;

for i = 1 : n
    imagesc(squeeze(mean(dyn.VVEL(:,:,:,i),2))') ;
    pause(.5);
end