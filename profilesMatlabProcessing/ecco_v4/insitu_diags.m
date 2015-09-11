function []=insitu_diags(dirMat,doComp,dirTex,nameTex);
%object:     driver for insitu_misfit and insitu_cost
%inputs:     dirMat is the directory where diagnozed .mat files will be saved
%                     -> set it to '' to use the default [dirModel 'mat/']
%            doComp states whether to compute (1) or display (0)
%            dirTex is the directory where tex and fig files will be created
%            nameTex is the tex file name (default : 'myPlots')
%
%notes : MITprof files will be used from the myenv.profiles directory
%            or [dirMat '/profiles/output/'] is myenv.profiles is missing

gcmfaces_global;

dirMat=[dirMat '/'];

if isfield(myenv,'profiles');
  dirData=myenv.profiles;
else;
  dirData=[dirMat '/profiles/output/'];
end;
while ~isdir(dirData)&doComp;
  fprintf(['directory : ' dirData '\n'])
  dirData=input(['does not exist. Specify directory of nc file : \n']);
end;

dirMat={'dirMat',dirMat};
dirData={'dirData',dirData};

if isempty(who('dirTex'));
  addToTex={'addToTex',0}; dirTex={'dirTex',''}; nameTex={'nameTex',''};
else;
  if ~ischar(dirTex); error('mis-specified dirTex'); end;
  if dirTex(1)~='/'; dirTex=[pwd '/' dirTex]; end; %make full path
  addToTex={'addToTex',1}; dirTex={'dirTex',[dirTex '/']};
  if isempty(who('nameTex')); nameTex='myPlots'; end;
  nameTex={'nameTex',nameTex};
end;

if doComp;
insitu_misfit(1,dirData,dirMat);
insitu_cost(1,dirData,dirMat);
else;
insitu_misfit(0,dirMat,addToTex,dirTex,nameTex);
insitu_cost(0,dirMat,addToTex,dirTex,nameTex);
end;

