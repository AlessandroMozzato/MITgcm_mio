% matlabvv
clear all
close all

% figure(1)
% H=rdmds('Depth'); 
% contourf('H');
% colorbar;
% title('Depth of fluid as used by model');

% eta=rdmds('Eta');
% imagesc(eta');
% axis ij;colorbar;
% title('Surface height at iter=10');
% 
% eta=rdmds('Eta',NaN);
% ww=rdmds('W',NaN);
% vv=rdmds('V',NaN);
% uu=rdmds('U',NaN);

state = rdmnc('state.*') ;
nn = length(state.iter) ;

% salt=rdmds('S',NaN);
% temp=rdmds('T',NaN);
% Ph=rdmds('PHL',NaN);

%pick = rdmds('pickup',NaN);

  
  % set(hFig, 'Position', [1200 1000 1200 600])
  
figure(1)
   
for n=1:1:nn;
    
    %         subplot(3,4,1)
    
    
subplot(3,3,1)
 imagesc(squeeze(squeeze(mean(state.Temp(:,:,:,n),1)))');
 axis ij;colorbar;
subplot(3,3,4)
 imagesc(squeeze(squeeze(mean(state.Temp(:,:,:,n),2)))');
    axis ij;colorbar;
subplot(3,3,7)
 imagesc(squeeze(squeeze(mean(state.Temp(:,:,:,n),3)))');
    axis ij;colorbar;
    
    subplot(3,3,2)
 imagesc(squeeze(squeeze(mean(state.V(:,:,:,n),1)))');
 axis ij;colorbar;
subplot(3,3,5)
 imagesc(squeeze(squeeze(mean(state.V(:,:,:,n),2)))');
    axis ij;colorbar;
subplot(3,3,8)
 imagesc(squeeze(squeeze(mean(state.V(:,:,:,n),3)))');
    axis ij;colorbar;
    
        subplot(3,3,3)
 imagesc(squeeze(squeeze(mean(state.U(:,:,:,n),1)))');
 axis ij;colorbar;
subplot(3,3,6)
 imagesc(squeeze(squeeze(mean(state.U(:,:,:,n),2)))');
    axis ij;colorbar;
subplot(3,3,9)
 imagesc(squeeze(squeeze(mean(state.U(:,:,:,n),3)))');
    axis ij;colorbar;
    
    
%     subplot(3,3,2)
%     imagesc(squeeze(mean(state.Temp(:,1,:,n))',1));
%     axis ij;colorbar;
% subplot(3,3,5)
%     imagesc(squeeze(mean(state.Temp(:,50,:,n))',1));
%     axis ij;colorbar;
% subplot(3,3,8)
%     imagesc(squeeze(mean(state.Temp(:,84,:,n))',1));
%     axis ij;colorbar;
%     
%        subplot(3,3,3)
%     imagesc(squeeze(mean(state.Temp(:,:,:,n))',1));
%     axis ij;colorbar;
% subplot(3,3,6)
%     imagesc(squeeze(state.Temp(:,:,2,n))');
%     axis ij;colorbar;
% subplot(3,3,9)
%     imagesc(squeeze(state.Temp(:,:,3,n))');
%     axis ij;colorbar;
    
    
%         subplot(3,4,2)
%     imagesc(squeeze(state.Temp(:,30,:,n)));
%     axis ij;colorbar;
%     
%         subplot(3,4,3)
%     imagesc(squeeze(state.Temp(:,50,:,n)));
%     axis ij;colorbar;
%     
%         subplot(3,4,4)
%     imagesc(squeeze(state.Temp(:,70,:,n)));
%     axis ij;colorbar;
% 
%         subplot(3,4,5)
%     imagesc(squeeze(state.S(:,10,:,n)));
%     axis ij;colorbar;
%     
%         subplot(3,4,6)
%     imagesc(squeeze(state.S(:,30,:,n)));
%     axis ij;colorbar;
%     
%         subplot(3,4,7)
%     imagesc(squeeze(state.S(:,50,:,n)));
%     axis ij;colorbar;
%     
%         subplot(3,4,8)
%     imagesc(squeeze(state.S(:,70,:,n)));
%     axis ij;colorbar;
  
    pause(.5);

end

