function [myStat]=profiles_subgrid_stats(KK,VV,TYPE,SUB,COORD);
%KK level choice
%VV variable choice
%TYPE 'obs' 'estim' or 'anom'
%SUB is the subsampling rate (box width=SUB)
%COORD is the coordinate type

%global variables:
gcmfaces_global;
global lon lat obs point;
global COORDOld; if isempty(COORDOld); COORDOld='x'; end;
global VVOld; if isempty(VVOld); VVOld='x'; end;
global TYPEOld; if isempty(TYPEOld); TYPEOld='x'; end;
global KKOld; if isempty(KKOld); KKOld=0; end;

%choice of time/depth ranges
if strcmp(COORD,'depth');
  %KK is ecco v4 level index; kk is corresponding MITprof level indices
  RC=squeeze(rdmds([myenv.gcmfaces_dir '/sample_input/GRIDv4/RC']));
  RF=squeeze(rdmds([myenv.gcmfaces_dir '/sample_input/GRIDv4/RF']));
  depth0=-RF(1:end-1); depth0(2:end-1)=depth0(1:end-2);
  depth1=-RF(2:end); depth1(2:end-1)=depth1(3:end);
  if KK>=1;
      depth0=depth0(KK); depth1=depth1(KK);%choice of depth range
  else;
      error('not implemented');
  end;
end;
%
date0=datenum(1950,1,1); date1=datenum(2049,12,31);%choice of time range

%get the grid:
grid_load([myenv.gcmfaces_dir '/sample_input/GRIDv4/'],5,'compact');
gcmfaces_bindata;

%get the data:
dirData='./';
listData=dir([dirData 'argo_2may13_set*.nc']);
listData={listData(:).name};
suffOut='argo';

%
test1=~strcmp(VV,VVOld)|~strcmp(TYPE,TYPEOld)|KK~=KKOld|~strcmp(COORD,COORDOld);
if test1;
    if strcmp(TYPE,'anom');
    [MITprof]=MITprof_stats_load(dirData,listData,VV,1);
    elseif strcmp(TYPE,'estim');
    [MITprof]=MITprof_stats_load(dirData,listData,VV,['prof_' VV 'estim']);
    else;
    [MITprof]=MITprof_stats_load(dirData,listData,VV,['prof_' VV]);
    end;
    %in DRHODR case, switch to log10 :
    if strcmp(VV,'DRHODR'); MITprof.prof=log10(MITprof.prof); end;
    %mask out values that are not in year range:
    ii=find(MITprof.prof_date<date0|MITprof.prof_date>date1);
    MITprof.prof(ii,:)=NaN;
    %restrict to depth range of interest:
    if strcmp(COORD,'depth');
      %KK is ecco v4 level index; kk is corresponding MITprof level indices
      kk=find(MITprof.prof_depth>=depth0&MITprof.prof_depth<=depth1);
    else;
      %kk is simply KK; assumes same density grid throughout 
      kk=KK;
    end;
    lon=MITprof.prof_lon; lat=MITprof.prof_lat; obs=MITprof.prof(:,kk);
end;
%
KKOld=KK;
VVOld=VV;
TYPEOld=TYPE;
COORDOld=COORD;

%get indices in full grid: (not necessarily the ecco_v4 one)
point=gcmfaces_bindata(lon,lat);

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
if SUB==0;
    %global computation
    indBox(:)=1;
else;
    %regional computation
    boxMax=0;
    for iFace=1:mygrid.nFaces;
        tmp1=indBox{iFace};
        tmp3=ceil([1:size(tmp1,1)]'/SUB);
        tmp4=(ceil([1:size(tmp1,2)]/SUB)-1)*max(tmp3);
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
tmp1=convert2array(0*mygrid.XC);
myStat.mea=tmp1; myStat.prc90=tmp1; myStat.med=tmp1; myStat.prc10=tmp1; myStat.nb=tmp1;
myStat.std=tmp1; myStat.iqr=tmp1; myStat.mad=tmp1;
%
for ii=boxList';
    if mod(ii,1000)==0;
        [KK ii length(boxList)]
    end;
    jj=find(box==ii);
    if length(jj)>=10;
        tmpStat=myStats(obs(jj));%need reduced params
        jj=find(indBox==ii);
        tmpList=fieldnames(tmpStat);
        for pp=1:length(tmpList);
          eval(['myStat.' tmpList{pp} '(jj)=tmpStat.' tmpList{pp} ';']);
        end;
    end;
end;
%
tmpList=fieldnames(myStat);
for pp=1:length(tmpList); 
  eval(['myStat.' tmpList{pp} '=convert2array(myStat.' tmpList{pp} ');']); 
end;

eval(['save ' dirData 'stats/' VV '_k' num2str(KK) '_' num2str(SUB) '.mat myStat;']);

function [myStat]=myStats(obs);

myStat.nb=sum(~isnan( obs ));

myStat.mea=mean(obs);%sample mean
myStat.prc10=prctile(obs,10);
myStat.med=median(obs);
myStat.prc90=prctile(obs,90);

myStat.std=std(obs);%sample standard deviation
myStat.iqr=0.7413*iqr(obs);%intequartile range estimate of std
myStat.mad=1.4826*mad(obs,1);%median absolute difference estimate of std

