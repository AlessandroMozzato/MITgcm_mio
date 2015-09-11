function [MITprof]=MITprof_stats_load(dirData,listData,varCur,varargin);
%[MITprof]=MITprof_stats_load(dirData,listData,varCur,varargin);
%object: loads a series of MITprof files, and computes
%          normalized misfits for one variable
%input:  dirData is the data directory name
%        listData is the data file list (e.g. {'argo_in*'} or {'argo_in*','argo_at*'} )
%        varCur is 'T' or 'S'
%optional :
% EITHER normFactor (optional; double) is the normalization factor (1./prof_?weight by default)
%   OR   varSpec (optional; char) is e.g. 'prof_T' or 'prof_Testim'
%output: MITprof.prof is the normalized misfit
%note:   by assumption, all of the files in listData must share the same vertical grid

normFactor=[]; varSpec='';
if nargin>3; 
  if isnumeric(varargin{1}); normFactor=varargin{1}; end; 
  if ischar(varargin{1}); varSpec=varargin{1}; end;
end;

useExtendedProfDepth=1;

%develop listData (that may include wildcards)
listData_bak=listData;
listData={};
for ii=1:length(listData_bak);
    tmp1=dir([dirData listData_bak{ii}]);
    for jj=1:length(tmp1);
      ii2=length(listData)+1;
      listData{ii2}=tmp1(jj).name;
    end;
end;
%avoid duplicates
listData=unique(listData);      

%loop over files
for iFile=1:length(listData);
    fileData=dir([dirData listData{iFile}]);
    fileData=fileData.name;
    fprintf(['loading ' varCur ' from ' fileData '\n']);
    MITprofCur=MITprof_load([dirData fileData]);
    
    %         fixes:
    if ~isfield(MITprofCur,'prof_S');
        tmp1=NaN*MITprofCur.prof_T;
        MITprofCur.prof_S=tmp1; MITprofCur.prof_Sestim=tmp1;
        MITprofCur.prof_Sweight=tmp1; MITprofCur.prof_Sflag=[];
    end;
    %         fixes
    if ~isfield(MITprofCur,['prof_' varCur 'weight']);
        eval(['MITprofCur.prof_' varCur 'weight=1+0*MITprofCur.prof_' varCur ';']);
    end;
    
    if ~isempty(normFactor);%replace weights with normFactor
        eval(['tmp1=MITprofCur.prof_' varCur 'weight;']);
        tmp1(tmp1>0)=normFactor;
        eval(['MITprofCur.prof_' varCur 'weight=tmp1;']);
    end;
    
    if varCur=='T';
        tmp1=(MITprofCur.prof_Testim-MITprofCur.prof_T).*sqrt(MITprofCur.prof_Tweight);
    else;
        tmp1=(MITprofCur.prof_Sestim-MITprofCur.prof_S).*sqrt(MITprofCur.prof_Sweight);
    end;
    %nan-mask
    tmp1(tmp1==0)=NaN;
    %replace non-masked values with varSpec?
    if ~isempty(varSpec);
      eval(['tmp2=MITprofCur.' varSpec ';']); tmp2(isnan(tmp1))=NaN; tmp1=tmp2;
    end;
    MITprofCur.prof=tmp1;
    
    listRm={'prof_T','prof_Testim','prof_Tweight','prof_Tflag','prof_Terr',...
            'prof_S','prof_Sestim','prof_Sweight','prof_Sflag','prof_Serr',...
            'prof_D','prof_Destim',...
            'prof_T_SOSE59','prof_S_SOSE59','prof_madt_aviso',...
            'prof_DRHODR','prof_DRHODRestim','prof_DRHODRweight',...
            'prof_RHOP','prof_RHOPestim','prof_RHOPweight'};
    for iRm=1:length(listRm);
        if isfield(MITprofCur,listRm{iRm}); MITprofCur=rmfield(MITprofCur,listRm{iRm}); end;
    end;
    
    MITprofCur.prof_date=datenum(num2str(MITprofCur.prof_YYYYMMDD*1e6+MITprofCur.prof_HHMMSS),'yyyymmddHHMMSS');
    %old:     ii=find(MITprofCur.prof_date<datenum(1992,1,1)|MITprofCur.prof_date>datenum(2008,12,27)); MITprofCur.prof(ii,:)=NaN;
    
    if useExtendedProfDepth;
        %use extended standard depth vector
        all_depth=[  0    5   10   15   20   25   30   35   45   50   55   65   75   85   95  100 ...
            105  115  125  135  145  150  155  165  175  185  200  220  240  250  260  280 ...
            300  320  340  360  380  400  420  440  460  480  500  550  600  650  700  750 ...
            800  850  900  950 1000 1100 1200 1300 1400 1500 1600 1700 1750 1800 1900 2000 2100 ...
            2200 2300 2400 2500 2600 2700 2800 2900 3000 3100 3200 3300 3400 3500 3600 3700 ...
            3800 3900 4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 ...
            5400 5500 5600 5700 5800 5900 6000 6500 7000 7500 8000 8500 9000];
        k_depth=NaN*zeros(1,MITprofCur.nr);
        for kk=1:MITprofCur.nr; k_depth(kk)=find(MITprofCur.prof_depth(kk)==all_depth); end;
        all_prof=NaN*ones(MITprofCur.np,length(all_depth));
        all_prof(:,k_depth)=MITprofCur.prof;
        MITprofCur.prof=all_prof;
        MITprofCur.nr=length(all_depth);
        MITprofCur.prof_depth=all_depth;
    end;
    
    if iFile==1;
        MITprof=MITprofCur;
    else;
        MITprof=MITprof_concat(MITprof,MITprofCur);
    end;
    clear MITprofCur;
end;


