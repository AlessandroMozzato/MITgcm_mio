function [profileCur]=profiles_prep_tests_basic(dataset,profileCur);
% [profileCur]=profiles_prep_tests_basic(dataset,profileCur)
%   basic range and resolution tests
%
% set profilCur.t_test (and profilCur.s_test) following the code:
%   0 = valid data
%   1 = not enough data near standard level
%   2 = absurd sal value
%   3 = doubtful profiler (based on our own evaluations)
%   4 = doubtful profiler (based on Argo grey list)
%   5 = high climatology/atlas cost - all four of them
%   6 = bad Pressure vector
%

profileCur.t_test=zeros(size(profileCur.t_std)); profileCur.s_test=profileCur.t_test;

%test for 'not enough data near standard level'
tmp1=ones(size(profileCur.z))'*dataset.z_top-profileCur.z'*ones(size(dataset.z_top));
tmp2=ones(size(profileCur.z))'*dataset.z_bot-profileCur.z'*ones(size(dataset.z_bot));
tmp1=tmp1<0; tmp2=tmp2>=0; tmp3=sum(tmp1.*tmp2,1);
profileCur.t_test((tmp3<=0)&(profileCur.t_std~=dataset.fillval))=1;
if dataset.inclS; profileCur.s_test((tmp3<=0)&(profileCur.s_std~=dataset.fillval))=1; end;

%test for "absurd" salinity values :
if dataset.inclS;
    profileCur.s_test(find( (profileCur.s_std>42)&(profileCur.s_std~=dataset.fillval) ))=2;
    profileCur.s_test(find( (profileCur.s_std<25)&(profileCur.s_std~=dataset.fillval) ))=2;
end;

%bad pressure flag:
if profileCur.PorZisBAD;
    profileCur.t_test(:)=10*profileCur.t_test(:)+6;
    if dataset.inclS; profileCur.s_test(:)=10*profileCur.s_test(:)+6; end;
end;

if isfield(profileCur,'DATA_MODE')&isfield(dataset,'greyList');

  test1=strcmp(profileCur.DATA_MODE,'R');%is real time profile
  test2=sum(strcmp(dataset.greyList.pnum,profileCur.pnum_txt));%is in grey list
  if test1&test2;
    II=find(strcmp(dataset.greyList.pnum,profileCur.pnum_txt));
    for ii=II;
      time0=datenum(dataset.greyList.start{ii});
      timeP=datenum(num2str(profileCur.ymd*1e6+profileCur.hms),'yyyymmddHHMMSS');
      if (time0<timeP);
        profileCur.t_test(:)=10*profileCur.t_test(:)+4;
        profileCur.s_test(:)=10*profileCur.s_test(:)+4;
      end;
    end;
  end;

% test1=strcmp(profileCur.DATA_MODE,'A');%is real time adjusted profile
% if test1;
%       profileCur.t_test(:)=10*profileCur.t_test(:)+4;
%       profileCur.s_test(:)=10*profileCur.s_test(:)+4;
% end;

end;


