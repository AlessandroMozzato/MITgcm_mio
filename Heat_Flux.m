% Meridional Heat Fluxes
% The following function was written in Matlab(R) to calculate salt and 
% heat fluxes broken down into time mean and time varying components 
% This function is ran in parallel for loops for each latband and 
% each year.
%This code is written in a formatt that allows publishing to Latex
function [TotalHeatFlux_PW, MeanHeatFlux_PW, EddyHeatFlux_PW, OverturningHeatFlux_PW, GyreHeatFlux_PW]=Heat_Flux(fname,Plot)
% First define global variables:
close all

state = rdmnc('state.*') ;
grid = rdmnc('grid.*') ;
nn = length(state.iter) ;

Z = state.Z' ;
Y = state.Y ;
X = state.X ;

%V = state.V ;
dx= 2.5e3;
lm = grid.HFacC ;

Cp=3985;
%Load data

V1=state.V;
T=state.Temp;
dz=Z(1:length(Z)-1)-Z(2:length(Z));
dz=[0-Z(1);dz];
%% Regrid Velocity to the centre 
% X,Yp1(South face of cell),Z to X,Y,Z (centre of cell)
V=zeros(size(T));
for i=1:length(Y)
    V(:,i,:,:)=mean(V1(:,i:i+1,:,:),2);
end
%% Create dA matrix
% Create a X,Z matrix with lm percentage closing for land
dA1=((ones(length(X),length(Y),length(Z)).*lm))*dx;
dA=zeros(length(X),length(Y),length(Z));
for i=1:length(Z)
    dA(:,:,i)=dA1(:,:,1)*dz(i);
end
dA=dA.*lm;
dA(dA==0)=NaN;
%% Density
Rho=linearEOSDens(fname,0,0);
Rho=nanmean(Rho,4);
%% Create Values required for final total and time mean transports
% $$ \overline{VT}=\overline{\overline{V}\overline{T}}+\overline{V'T'} $$
VT=V.*T;
Vtave=squeeze(nanmean(V,4));
Ttave=squeeze(nanmean(T,4));
VTtave=squeeze(nanmean(VT,4));
%Total Flux: Timeav sum of VT product.*dA over the section.
% $$ \sum\sum \overline{VT} \Delta x \Delta z $$
TotalHeatFlux=nansum(VTtave.*dA.*Rho);
TotalHeatFlux_PW=Cp*nansum(TotalHeatFlux,3)/(10^15);%Divide by 10^15 to get into PW!

%Mean_Flux: sum of Product of time averaged V and T * dA over the section
% $$ \sum\sum \overline{V}\overline{T} \Delta x \Delta z $$
MeanHeatFlux=nansum(Vtave.*Ttave.*dA.*Rho);
MeanHeatFlux_PW=Cp*nansum(MeanHeatFlux,3)/10^15;

%Eddy Flux: Time av sum of V'Y' * dA over section
% $$ \sum\sum \overline{V'T'} \Delta x \Delta z $$
VTprime=zeros(length(X),length(Y),length(Z),length(V(1,1,1,:)));
%Calculate V' and S' at each timestep:
for t=1:length(V(1,1,1,:))
Vprimet=V(:,:,:,t)-Vtave;
Tprimet=T(:,:,:,t)-Ttave;
VTprime(:,:,:,t)=(Vprimet.*Tprimet);
end

%Time average V'S'
VTprime=nanmean(VTprime,4);
Eddy2=(VTprime);
Eddy3=nansum(Eddy2.*dA.*Rho);
EddyHeatFlux_PW=Cp*(nansum(Eddy3,3)/10^15);


%% Overturing = $<V><T>$
Vtave(Vtave==0)=NaN;
Ttave(Ttave==0)=NaN;
Vzone=squeeze(nanmean(Vtave,1));
Tzone=squeeze(nanmean(Ttave,1));
dw=dA;
dw(dw==0)=NaN;
Width=squeeze(nansum(~isnan(dw),1))*dx;
ovt=zeros(length(Y),length(Z));
Rhoav=squeeze(nanmean(Rho,1));
for i = 1:length(Z)
ovt(:,i)=(Rhoav(:,i).*Width(:,i).*Vzone(:,i).*Tzone(:,i)*dz(i));
end
OverturningHeatFlux_PW=Cp*(squeeze(nansum(ovt,2)))/10^15;
%% Gyre FLux:

%T* and V*

Vstar=zeros(length(X),length(Y),length(Z));
Tstar=zeros(length(X),length(Y),length(Z));
VzoneTstar=zeros(length(X),length(Y),length(Z));
VstarTzone=zeros(length(X),length(Y),length(Z));
for i=1:length(X);
    Vstar(i,:,:)=squeeze(Vtave(i,:,:))-Vzone;
    Tstar(i,:,:)=squeeze(Ttave(i,:,:))-Tzone;
    VstarTzone(i,:,:)=squeeze(Vstar(i,:,:)).*Tzone;
    VzoneTstar(i,:,:)=Vzone.*squeeze(Tstar(i,:,:));
end

VTstar=Vstar.*Tstar;
Gyre1_PW=Cp*(nansum(nansum(VTstar.*dA.*Rho,1),3))/10^15;
Gyre2_PW=Cp*(nansum(nansum(VstarTzone.*dA.*Rho,1),3))/10^15;
Gyre3_PW=Cp*(nansum(nansum(VzoneTstar.*dA.*Rho,1),3))/10^15;
GyreHeatFlux_PW=Gyre1_PW+Gyre2_PW+Gyre3_PW;

if Plot == 1
plot(Y/1000,TotalHeatFlux_PW,'-k','linewidth',2)
hold on
plot(Y/1000,EddyHeatFlux_PW,'-b','linewidth',2)
hold on
plot(Y/1000,MeanHeatFlux_PW,'-r','linewidth',2)
title('Meridional Heat Flux in Nautilus run 1','fontsize',12)
ylabel('Meridional Heat Transport (PW)','fontsize',12)
xlabel('Meridional Distance (km)','fontsize',12)
h=legend('Total $\overline{VT}$','Eddy $V{^\prime}T{^\prime}$','Mean $\overline{V}$ $\overline{T}$');
set(h,'interpreter','latex','fontsize',14)
cd ~/Figures/Nautilus/Run1/
figure
plot(Y/1000,TotalHeatFlux_PW,'-k','linewidth',2);
hold on
plot(Y/1000,EddyHeatFlux_PW,'-b','linewidth',2);
hold on
plot(Y/1000,OverturningHeatFlux_PW,'-r','linewidth',2);
hold on
plot(Y/1000,GyreHeatFlux_PW,'-g','linewidth',2);
title('Meridional Heat Flux in Nautilus Run 1','fontsize',12)
ylabel('Meridional Heat Transport (PW)','fontsize',12)
xlabel('Meridional Distance (km)','fontsize',12)
h=legend('Total $\overline{VT}$','Eddy $V{^\prime}T{^\prime}$','Overturning $<\overline{V}> <\overline{T}>$','Gyre V*T*');
set(h,'interpreter','latex','fontsize',14)
end
end