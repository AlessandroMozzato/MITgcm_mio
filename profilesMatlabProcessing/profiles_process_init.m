clear all

gcmfaces_global;
myenv.verbose=1;

fprintf('\n\n basic MITprof test: started... \n');

if myenv.verbose;
fprintf('\nadding directories to your path\n');
fprintf('===============================\n\n')
end;
MITprof_global;

if myenv.verbose;
fprintf('\nloading  reference grid and climatology\n')
fprintf('========================================\n\n')
end;
profiles_prep_load_fields;

if myenv.verbose;
fprintf('\nrunning main program on sample data sets\n')
fprintf('========================================\n\n')
end;

%select the data source (and specific params) => wod05 sample
dataset=profiles_prep_select('wod05','90CTD');
%process it
profiles_prep_main(dataset);
%
fprintf(['\n\n wod05 sample -- done -- ' dataset.dirOut dataset.fileOut '.nc was created \n\n']);

%select the data source (and specific params) => argo sample
dataset=profiles_prep_select('argo','indian'); 
%process it
profiles_prep_main(dataset);
%
fprintf(['\n\nargo sample -- done -- ' dataset.dirOut dataset.fileOut '.nc was created \n\n']);

%select the data source (and specific params) => odv sample
dataset=profiles_prep_select('odv','ODVcompact_sample');
%process it
profiles_prep_main(dataset);
%
fprintf(['\n\nodv sample -- done -- ' dataset.dirOut dataset.fileOut '.nc was created \n\n']);

fprintf('\n basic MITprof test: completed. \n');

