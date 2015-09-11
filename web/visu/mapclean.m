%
% SUBFCT_MAPCLEAN(CPLOT,CBAR)
%
% This function makes uniformed subplots (handles CPLOT)
% and their vertical colorbars (handles CBAR)
%
% 07/06/06
% gmaze@mit.edu

function subfct_mapclean(CPLOT,CBAR)


np = length(CPLOT);
proper1 = 'position';
proper2 = 'position';

% Get positions of subplots and colorbars:
for ip = 1 : np
  Pot(ip,:) = get(CPLOT(ip),proper1);
  Bot(ip,:) = get(CBAR(ip),proper2);
end


% Set coord of subplots: [left bottom width height]
W = max(Pot(:,3));
H = max(Pot(:,4));
Pot;
for ip = 1 : np
  set(CPLOT(ip),proper1,[Pot(ip,1:2) W H]);
end


% Get new positions of subplots:
for ip = 1 : np
  Pot(ip,:) = get(CPLOT(ip),proper1);
end


% Fixe colorbars coord: [left bottom width height]
Wmin = 0.0435*min(Pot(:,3));
Hmin = 0.6*min(Pot(:,4));

% Set them:
for ip = 1 : np
  %set(CBAR(ip),proper2,[Bot(ip,1) Bot(ip,2) Wmin Hmin]);
%  set(CBAR(ip),proper2,[Pot(ip,1)+Pot(ip,3)*1.1 Pot(ip,2)+Pot(ip,2)*0.1 Wmin Hmin]);
  set(CBAR(ip),proper2,[Pot(ip,1)+Pot(ip,3)*1.05 Pot(ip,2)+Pot(ip,4)*0.2 ...
		        0.0435*Pot(ip,3) 0.6*Pot(ip,4)])
end
