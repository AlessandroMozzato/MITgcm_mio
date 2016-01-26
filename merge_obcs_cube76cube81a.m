clear all
dirRoot='/net/nares/raid8/ecco-shared/arctic18km/';
dirGrid=[dirRoot 'GRID/'];
dir81=[dirRoot 'run_template_cube81/'];nT81=230;
dir76=[dirRoot 'run_template_cube76/'];nT76=336;
nx=420;ny=384;nz=50;yrStart=1979;str=[num2str(nx) 'x' num2str(ny)];
DYG=readbin([dirGrid 'DYG.data'],[nx ny]);
DXG=readbin([dirGrid 'DXG.data'],[nx ny]);
hFacC=readbin([dirGrid 'hFacC.data'],[nx ny nz]);
hFacW=readbin([dirGrid 'hFacW.data'],[nx ny nz]);
hFacS=readbin([dirGrid 'hFacS.data'],[nx ny nz]);
GRID_25;
Lend76=length([1979:1991])*12+1;	%13*12+1=157
Lend81=length([1992:2006])*12+1;

merging_cube76cube81=0;
if(merging_cube76cube81==1);
%west + east (Bering Strait):
obcs={'W','E','N'};
for iobcs=1:size(obcs,2);
  if(iobcs==1);
    indx=1;indy=1:ny;DG=DYG;nL=ny;
  elseif(iobcs==2);
    indx=nx;indy=1:ny;DG=DYG;nL=ny;
  elseif(iobcs==3);
    indx=1:nx;indy=ny;DG=DXG;nL=nx;
  end;
  for k=1:nz;Area(:,k)=DG(indx,indy).*thk25(k);end;

  T81a=readbin([dir81 '+old/OB' obcs{iobcs} 't_arctic_420x384_20072010.bin'],[nL nz 49]);
  T81 =readbin([dir81 '+old/OB' obcs{iobcs} 't_arctic_420x384.bin'],[nL nz nT81]);
  T76 =readbin([dir76 'OB' obcs{iobcs} 't_arctic_420x384.bin'],[nL nz nT76]);
  T81e=cat(3,T81a(:,:,38:49),T81a(:,:,38:49),T81a(:,:,38:49),T81a(:,:,38:49));%jan2011-dec2014
  mask=ones(nL,nz);mask(find(T81(:,:,1)==0))=0;
  T81=T81.*mk3D_mod(mask,T81);T76=T76.*mk3D_mod(mask,T76);
  T81a=T81a.*mk3D_mod(mask,T81a);

  S81a=readbin([dir81 '+old/OB' obcs{iobcs} 's_arctic_420x384_20072010.bin'],[nL nz 49]);
  S81 =readbin([dir81 '+old/OB' obcs{iobcs} 's_arctic_420x384.bin'],[nL nz nT81]);
  S76 =readbin([dir76 'OB' obcs{iobcs} 's_arctic_420x384.bin'],[nL nz nT76]);
  S81e=cat(3,S81a(:,:,38:49),S81a(:,:,38:49),S81a(:,:,38:49),S81a(:,:,38:49));%jan2011-dec2014
  S81 =S81.*mk3D_mod(mask,S81);S76=S76.*mk3D_mod(mask,S76);
  S81a=S81a.*mk3D_mod(mask,S81a);

  U81a=readbin([dir81 '+old/OB' obcs{iobcs} 'u_arctic_420x384_20072010.bin'],[nL nz 49]);
  U81 =readbin([dir81 '+old/OB' obcs{iobcs} 'u_arctic_420x384.bin'],[nL nz nT81]);
  U76 =readbin([dir76 'OB' obcs{iobcs} 'u_arctic_420x384.bin'],[nL nz nT76]);
  U81e=cat(3,U81a(:,:,38:49),U81a(:,:,38:49),U81a(:,:,38:49),U81a(:,:,38:49));%jan2011-dec2014
  U81=U81.*mk3D_mod(mask,U81);U76=U76.*mk3D_mod(mask,U76);
  U81a=U81a.*mk3D_mod(mask,U81a);

  V81a=readbin([dir81 '+old/OB' obcs{iobcs} 'v_arctic_420x384_20072010.bin'],[nL nz 49]);
  V81=readbin([dir81 '+old/OB' obcs{iobcs} 'v_arctic_420x384.bin'],[nL nz nT81]);
  V76=readbin([dir76 'OB' obcs{iobcs} 'v_arctic_420x384.bin'],[nL nz nT76]);
  V81e=cat(3,V81a(:,:,38:49),V81a(:,:,38:49),V81a(:,:,38:49),V81a(:,:,38:49));%jan2011-dec2014
  V81 =V81.*mk3D_mod(mask,V81);V76=V76.*mk3D_mod(mask,V76);
  V81a=V81a.*mk3D_mod(mask,V81a);

  newT=cat(3,T76(:,:,1:Lend76),T81(:,:,2:Lend81),T81a(:,:,2:end),T81e);
  newS=cat(3,S76(:,:,1:Lend76),S81(:,:,2:Lend81),S81a(:,:,2:end),S81e);
  newU=cat(3,U76(:,:,1:Lend76),U81(:,:,2:Lend81),U81a(:,:,2:end),U81e);
  newV=cat(3,V76(:,:,1:Lend76),V81(:,:,2:Lend81),V81a(:,:,2:end),V81e);
 
  writebin([dir81 'OB' obcs{iobcs} 't_arctic_420x384_19792014m.bin'],newT);
  writebin([dir81 'OB' obcs{iobcs} 's_arctic_420x384_19792014m.bin'],newS);
  writebin([dir81 'OB' obcs{iobcs} 'u_arctic_420x384_19792014m.bin'],newU);
  writebin([dir81 'OB' obcs{iobcs} 'v_arctic_420x384_19792014m.bin'],newV);

  transport76 =squeeze(sum(sum(U76.*mk3D_mod(Area,U76))));
  transport81 =squeeze(sum(sum(U81.*mk3D_mod(Area,U81))));
  transport81a=squeeze(sum(sum(U81a.*mk3D_mod(Area,U81a))));
  transportnew=squeeze(sum(sum(newU.*mk3D_mod(Area,newU))));

  Heat76 =squeeze(sum(sum(U76.*T76.*mk3D_mod(Area,U76))));
  Heat81 =squeeze(sum(sum(U81.*T81.*mk3D_mod(Area,U81))));
  Heat81a=squeeze(sum(sum(U81a.*T81a.*mk3D_mod(Area,U81a))));
  Heatnew=squeeze(sum(sum(newU.*newT.*mk3D_mod(Area,newU))));

  Salt76 =squeeze(sum(sum(U76.*S76.*mk3D_mod(Area,U76))));
  Salt81 =squeeze(sum(sum(U81.*S81.*mk3D_mod(Area,U81))));
  Salt81a=squeeze(sum(sum(U81a.*S81a.*mk3D_mod(Area,U81a))));
  Saltnew=squeeze(sum(sum(newU.*newS.*mk3D_mod(Area,newU))));

  t76=[-1:nT76-2]./12+yrStart;
  t81=[-1:nT81-2]./12+1992;
  t81a=[-1:49-2]./12+2007;
  newt=[t76(1:Lend76),t81(2:Lend81),t81a(2:end),t81a(2:end)+4];
  tp=1:nT76;

  figure(1);clf;
  subplot(311);plot(t81,transport81,'b.-',t76,transport76,'r.-',t81a,transport81a,'mo--');grid;
    hold on;plot(newt,transportnew,'g^--');hold off;
    set(gca,'Xlim',[1978,2015],'Xtick',1980:2015);ylabel('transport');
    hold on;plot(t76([2:12:nT76]),-0.8e8.*ones(size([2:12:nT76])),'.-');hold off;
    for k=2:12:length(tp);text(t76(k),-.8e8,num2str(tp(k)));end;
  subplot(312);plot(t81,Heat81,'b.-',t76,Heat76,'r.-',t81a,Heat81a,'mo--');grid;
    hold on;plot(newt,Heatnew,'g^--');hold off;
    set(gca,'Xlim',[1978,2015],'Xtick',1980:2015);ylabel('Heat');
  subplot(313);plot(t81,Salt81,'b.-',t76,Salt76,'r.-',t81a,Salt81a,'mo--');grid;
    hold on;plot(newt,Saltnew,'g^--');hold off;
    set(gca,'Xlim',[1978,2015],'Xtick',1980:2015);ylabel('Salt');
  
  clear west* Heat* transport* Salt* Area mask new*
  clear V76 V81 V81e V81a U76 U81 U81e U81a T76 T81 T81e T81a S76 S81 S81e S81a

end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%done over at mk_obcs_cube81_20072010.m, now plotting newly balance/stable cube81/cube76 merge
%versus old cube81 balance/stable:
nTo=230;
nTn=433;
nTob=494;
obcs={'W','E','N'};
for iobcs=1:size(obcs,2);
  if(iobcs==1);
    indx=1;indy=1:ny;DG=DYG;nL=ny;ext='.bin';
  elseif(iobcs==2);
    indx=nx;indy=1:ny;DG=DYG;nL=ny;ext='.bin';
  elseif(iobcs==3);
    indx=1:nx;indy=ny;DG=DXG;nL=nx;ext='.balance';
  end;
  for k=1:nz;Area(:,k)=DG(indx,indy).*thk25(k);end;

  T81ob=readbin([dir81 '+obsolete/OB' obcs{iobcs} 't_arctic_420x384_19792019m.stable'],[nL nz nTob]);
  T81o=readbin([dir81 '+old/OB' obcs{iobcs} 't_arctic_420x384.stable'],[nL nz nTo]);
  T81n=readbin([dir81      'OB' obcs{iobcs} 't_arctic_420x384_19792014m.stable'],[nL nz nTn]);

  S81ob=readbin([dir81 '+obsolete/OB' obcs{iobcs} 's_arctic_420x384_19792019m.stable'],[nL nz nTob]);
  S81o=readbin([dir81 '+old/OB' obcs{iobcs} 's_arctic_420x384.stable'],[nL nz nTo]);
  S81n=readbin([dir81      'OB' obcs{iobcs} 's_arctic_420x384_19792014m.stable'],[nL nz nTn]);

  U81ob=readbin([dir81 '+obsolete/OB' obcs{iobcs} 'u_arctic_420x384_19792019m.bin'],[nL nz nTob]);
  U81o=readbin([dir81 '+old/OB' obcs{iobcs} 'u_arctic_420x384.bin'],[nL nz nTo]);
  U81n=readbin([dir81      'OB' obcs{iobcs} 'u_arctic_420x384_19792014m.bin'],[nL nz nTn]);

  V81ob=readbin([dir81 '+obsolete/OB' obcs{iobcs} 'v_arctic_420x384_19792019m' ext],[nL nz nTob]);
  V81o=readbin([dir81 '+old/OB' obcs{iobcs} 'v_arctic_420x384' ext],[nL nz nTo]);
  V81n=readbin([dir81      'OB' obcs{iobcs} 'v_arctic_420x384_19792014m' ext],[nL nz nTn]);

  transportob=squeeze(sum(sum(U81ob.*mk3D_mod(Area,U81ob))));
  transporto =squeeze(sum(sum(U81o.*mk3D_mod(Area,U81o))));
  transportn =squeeze(sum(sum(U81n.*mk3D_mod(Area,U81n))));

  Heatob=squeeze(sum(sum(U81ob.*T81ob.*mk3D_mod(Area,U81ob))));
  Heato =squeeze(sum(sum(U81o.*T81o.*mk3D_mod(Area,U81o))));
  Heatn =squeeze(sum(sum(U81n.*T81n.*mk3D_mod(Area,U81n))));

  Saltob=squeeze(sum(sum(U81ob.*S81ob.*mk3D_mod(Area,U81ob))));
  Salto =squeeze(sum(sum(U81o.*S81o.*mk3D_mod(Area,U81o))));
  Saltn =squeeze(sum(sum(U81n.*S81n.*mk3D_mod(Area,U81n))));

  tob=[-1:nTob-2]./12+1979;
  to=[-1:nTo-2]./12+1992;
  tn=[-1:nTn-2]./12+1979;

  figure(1);clf;
  subplot(311);plot(tob,transportob,'g^-',to,transporto,'bo-',tn,transportn,'r.-');grid;
    set(gca,'Xlim',[1978,2020],'Xtick',1980:5:2020);ylabel('transport');
  subplot(312);plot(tob,Heatob,'g^-',to,Heato,'bo-',tn,Heatn,'r.-');grid;
    set(gca,'Xlim',[1978,2020],'Xtick',1980:5:2020);ylabel('Heat');
  subplot(313);plot(tob,Saltob,'g^-',to,Salto,'bo-',tn,Saltn,'r.-');grid;
    set(gca,'Xlim',[1978,2020],'Xtick',1980:5:2020);ylabel('Salt');

  clear Heat* transport* Salt* Area mask
  clear V81* U81* T81* S81*
end;