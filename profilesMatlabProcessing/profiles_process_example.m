

%% select the data source (and specific params) => wod05 sample
cd /Users/roquet/Documents/MATLAB/MITprof
dataset=profiles_prep_select('wod05','90CTD');
profiles_prep_main(dataset);
fprintf(['\n\n wod05 sample -- done -- \n\n']);

%% select the data source (and specific params) => argo sample
cd /Users/roquet/Documents/MATLAB/MITprof
dataset=profiles_prep_select('argo','indian');
profiles_prep_main(dataset);
fprintf(['\n\n argo sample -- done -- \n\n']);

%% select the data source (and specific params) => odv sample
cd /Users/roquet/Documents/MATLAB/MITprof
dataset=profiles_prep_select('odv','ODVcompact_sample');
profiles_prep_main(dataset);
fprintf(['\n\n odv sample -- done -- \n\n']);

%%
fprintf('\n basic MITprof test: completed. \n');

