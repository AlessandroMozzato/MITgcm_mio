function [profileCur]=profiles_prep_interp(dataset,profileCur);
%[profileCur]=profiles_prep_interp(dataset,profileCur);
%	interpolate profileCur to dataset.z_std standard levels


z_std=dataset.z_std; 
t_std=NaN*z_std; 
tE_std=t_std; 
if dataset.inclS; 
    s_std=t_std; 
    sE_std=t_std; 
end;
z=profileCur.z; 
t=profileCur.t; 
if dataset.inclS; s=profileCur.s; end;
t_ERR=profileCur.t_ERR; 
if dataset.inclS; s_ERR=profileCur.s_ERR; end;


% temperature
if ~isempty(t)&length(find(~isnan(z.*t)))>1;
    tmp1=find( ~isnan(t) & ~isnan(z) );                     %compact
    z_in=z(tmp1);
    t_in=t(tmp1);
    tE_in=t_ERR(tmp1);
    [z_in,tmp1]=sort(z_in);
    t_in=t_in(tmp1);
    tE_in=tE_in(tmp1);%sort
    tmp1=[find(z_in(1:end-1)~=z_in(2:end))   length(z_in)];
    z_in=z_in(tmp1);
    t_in=t_in(tmp1);
    tE_in=tE_in(tmp1);    %avoid duplicate
    if length(t_in)>5 %...expected to avoid isolated values
        t_std = interp1(z_in,t_in,z_std);
        tE_std = interp1(z_in,tE_in,z_std);
    end
end%if ~isempty(t);
t_std(find(isnan(t_std)))=dataset.fillval; profileCur.t_std=t_std;
tE_std(find(isnan(tE_std)))=dataset.fillval; profileCur.tE_std=tE_std;


%interpolation for S :
if dataset.inclS;
    if ~isempty(s)&length(find(~isnan(z.*s)))>1;
        tmp1=find( ~isnan(s) & ~isnan(z) );                     %compact
        z_in=z(tmp1);
        s_in=s(tmp1);
        sE_in=s_ERR(tmp1);
        [z_in,tmp1]=sort(z_in);
        s_in=s_in(tmp1);
        sE_in=sE_in(tmp1);%sort
        tmp1=[find(z_in(1:end-1)~=z_in(2:end))   length(z_in)];
        z_in=z_in(tmp1);
        s_in=s_in(tmp1);
        sE_in=sE_in(tmp1);    %avoid duplicate
        if length(s_in)>5
            s_std = interp1(z_in,s_in,z_std);
            sE_std = interp1(z_in,sE_in,z_std);
        end
    end%if ~isempty(s)
    s_std(find(isnan(s_std)))=dataset.fillval; profileCur.s_std=s_std;
    sE_std(find(isnan(sE_std)))=dataset.fillval; profileCur.sE_std=sE_std;
end


