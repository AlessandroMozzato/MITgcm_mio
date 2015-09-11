function [myStat]=profiles_subgrid_stats(choiceProf,choiceLevel,choiceVar,choiceGrid,subGridN);

%note : in wod09 ctd, we will use kk=2 to 33
% subGridN=8;%on the cs24 grid
% subGridN=18;%on the llc grid
%next things I need to do :
%   IO/memory store
%   loop over subGridN
%   proper treatment of choiceLevel


%global variables:
gcmfaces_global;
global lon lat obs point;
global choiceGridOld; if isempty(choiceGridOld); choiceGridOld='x'; end;
global choiceProfOld; if isempty(choiceProfOld); choiceProfOld='x'; end;
global choiceVarOld; if isempty(choiceVarOld); choiceVarOld='x'; end;
global choiceLevelOld; if isempty(choiceLevelOld); choiceLevelOld=0; end;

%choice of time/depth ranges
RC=squeeze(rdmds('/net/weddell/raid3/gforget/ecco_v4/GRID/RC'));
RF=squeeze(rdmds('/net/weddell/raid3/gforget/ecco_v4/GRID/RF'));
depth0=-RF(1:end-1); depth0(2:end-1)=depth0(1:end-2);
depth1=-RF(2:end); depth1(2:end-1)=depth1(3:end);
if choiceLevel>=1;
    depth0=depth0(choiceLevel); depth1=depth1(choiceLevel);%choice of depth range
else;
    error('not implemented');
end;
%
date0=datenum(1950,1,1); date1=datenum(2049,12,31);%choice of time range

%get the grid:
if strcmp(choiceGrid,'cs24')&~strcmp(choiceGrid,choiceGridOld);
    dirGrid='/net/weddell/raid3/gforget/grids/gridCompleted/cube_FM/';
%    dirGrid='/Users/gforget/mywork/projects_inprogress/2012mayInputs/insitu/processed/';
    grid_load_native([dirGrid 'cube_24/'],6);
    gcmfaces_bindata;
elseif strcmp(choiceGrid,'cs96')&~strcmp(choiceGrid,choiceGridOld);
    dirGrid='/net/weddell/raid3/gforget/grids/gridCompleted/cube_FM/';
%    dirGrid='/Users/gforget/mywork/projects_inprogress/2012mayInputs/insitu/processed/';
    grid_load_native([dirGrid 'cube_96/'],6);
    gcmfaces_bindata;
elseif strcmp(choiceGrid,'v4')&~strcmp(choiceGrid,choiceGridOld);
    dirGrid='/net/nares/raid10/gforget/2012julyIters/GRID/';
    %dirGrid='/net/weddell/raid3/gforget/ecco_v4/GRID/';
    grid_load(dirGrid,5,'compact');
    gcmfaces_bindata;
end;
%
choiceGridOld=choiceGrid;

%get the data:
if strcmp(choiceProf,'argo');
  dirData='/net/nares/raid11/ecco-shared/ecco-version-4/input/input_insitu/';
  listData={'argo_june2012_1992_to_2007*','argo_june2012_2008_to_2010*','argo_june2012_2011_to_2012*'};
  suffOut='argo';
elseif strcmp(choiceProf,'model');
  dirData='/net/nares/raid10/gforget/2012julyIters/ecco_it0003_link/mat/profiles/output/';
  listData={'argo_june2012_1992_to_2007_model*','argo_june2012_2008_to_2010_model*','argo_june2012_2011_to_2012_model*'};
  suffOut='model';
else;
  dirData='/net/nares/raid11/gforget/2012mayInputs/insitu/processed/';
  listData=dir([dirData '*.nc']);
  for ii=1:length(listData); listData(ii).name=[listData(ii).name(1:end-3) '*']; end;
  listData={listData(:).name};
  %for ~ backward compatibility:
  %listRm={'itp_MITprof*','bobbers_MITprof*','CLIMODE_Talley_ctd*','WOD09_XBT*'};
  %remove climode and xbts
  listRm={'bobbers_MITprof*','CLIMODE_Talley_ctd*','WOD09_XBT*'};
  for ii=1:length(listRm); tmp1=find(~strcmp(listData,listRm{ii})); listData={listData{tmp1}}; end;
  suffOut='';
end;
%
test1=~strcmp(choiceProf,choiceProfOld)|...
    ~strcmp(choiceVar,choiceVarOld)|...
    choiceLevel~=choiceLevelOld;
if test1;
    [MITprof]=MITprof_stats_load(dirData,listData,choiceVar,['prof_' choiceVar suffOut]);
    %in DRHODR case, switch to log10 :
    if strcmp(choiceVar,'DRHODR'); MITprof.prof=log10(MITprof.prof); end;
    %mask out values that are not in year range:
    ii=find(MITprof.prof_date<date0|MITprof.prof_date>date1);
    MITprof.prof(ii,:)=NaN;
    %restrict to depth range of interest:
    kk=find(MITprof.prof_depth>=depth0&MITprof.prof_depth<=depth1);
    lon=MITprof.prof_lon; lat=MITprof.prof_lat; obs=MITprof.prof(:,kk);
end;
%
choiceLevelOld=choiceLevel;
choiceVarOld=choiceVar;
choiceProfOld=choiceProf;

%get indices in full grid: (not necessarily the ecco_v4 one)
point=gcmfaces_bindata(lon,lat);

if strcmp(choiceVar,'RHOP'); 
  binE=[1015:0.2:1030];
else;
  error('need to specify binE');
end;
nB=length(binE);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check nearest neighbor mapping:
% [tmp1,tmp2]=gcmfaces_bindata(lon,lat,lon);
% figureL; qwckplot(log10(tmp2));
% figureL; qwckplot(tmp1./tmp2);

%map of full grid indices: (consistent with prof_point2)
indGrid=convert2array(mygrid.XC);
indGrid(:)=[1:length(indGrid(:))];
indGrid=convert2array(indGrid);

%reduce grid and map reduced grid indices:
indBox=mygrid.XC;
if subGridN==0;
    %global computation
    indBox(:)=1;
else;
    %regional computation
    boxMax=0;
    for iFace=1:mygrid.nFaces;
        tmp1=indBox{iFace};
        tmp3=ceil([1:size(tmp1,1)]'/subGridN);
        tmp4=(ceil([1:size(tmp1,2)]/subGridN)-1)*max(tmp3);
        tmp5=tmp3*ones(1,size(tmp1,2))+ones(size(tmp1,1),1)*tmp4;
        indBox{iFace}=tmp5+boxMax;
        boxMax=boxMax+max(tmp5(:));
    end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%main computational loop: stats for each region in indBox
%
indBox=convert2array(indBox);
box=repmat(indBox(point),[1 size(obs,2)]);
box(isnan(obs))=NaN;
boxList=unique(indBox(:));
boxList=boxList(find(~isnan(boxList)));
%
myStat.nb=zeros(360*360,1);
myStat.dist=zeros(360*360,nB);
%
for ii=boxList';
    if mod(ii,1000)==0;
        [choiceLevel ii length(boxList)]
    end;
    jj=find(box==ii);
    if length(jj)>=10;
        n=histc(obs(jj),binE);
        jj=find(indBox==ii);
        myStat.nb(jj)=sum(n);
        myStat.dist(jj,:)=ones(length(jj),1)*n'/sum(n);
    end;
end;
%
myStat.nb=reshape(myStat.nb,[360 360]);
myStat.dist=reshape(myStat.dist,[360 360 nB]);
myStat.nb=convert2array(myStat.nb);
myStat.dist=convert2array(myStat.dist);

