%% Density Calclator
function [Rho]=linearEOSDens(section,plot,tref)
%% This function uses a linea equation of state to calculate density from t
% The Equation of state:
% rho = rhoNil*(1+sBeta*S - tAlpha*T)
% Where the linear version does not depend on salinity (set to 35psu in my
% model)
%So becomes:
%rho = rhoNil*(1-tAlpha*T)
%Where T=t-tref
%These values are set in the data file
%% Inputs
% fname = string of file name to read
% section: 1 = Yes take a Y,Z section 0 == output whole density field
% plot: 1 = Yes print out a plot else not!
%% Load variables
global T
global Yc
global Zc
global lmc
%lmc(lmc<1)=NaN; 
%% Section or not
if section ==1 
Tavlat=mean(T,4);
Tavlat=Tavlat.*lmc;
Tavlat=squeeze(nanmean(Tavlat));
elseif section == 0
   Tavlat=T;
end
%% Linear EOS
Tavlat(Tavlat==0)=NaN;
RhoNil=1000;
tAlpha=2*10^-4;
for i=1:length(Zc)
Rho=RhoNil*(1-(tAlpha*(Tavlat-tref(i))));
end
%% Plot or not to Plot
if plot==1
imagesc(Yc/1000,Zc,Rho');
set(gca,'YDir','normal')
title('Density Field From T-field using linear EOS','fontsize',12)
h=colorbar;
ylabel(h,'Density (kg/m^3)','fontsize',12)
xlabel('Meridional distance (km)','fontsize',12)
ylabel('Depth (m)','fontsize',12)
end
% Can return back a temp matix from a density field
%Temp=((RhoNil-Rho)/(2*10^-4*RhoNil))+tref;
%figure
%imagesc(Y/1000,Z,Temp');
%set(gca,'YDir','normal')
end
