function C2O_KernalXCRC(dataset,totN)

%setup viper mat files
setup_viper 

% loading the partitions
load(fullfile(workDir,'data',sprintf('%s_trials.mat',dataset)));

%  Loading features and partitions     
params.N = 316;
params.Iter =1;
params.saveDir = strcat('.\Graphics\',dataset,'\'); 

c2o_params.totN=totN;
c2o_params.iter_id=1;
c2o_params.dataset='viper';


%allocate first half of images to the training
params.idxtrain=trials(c2o_params.iter_id).labelsAtrain;

%allocate second half to the non training
c2o_params.non_trains=trials(c2o_params.iter_id).labelsAtest;

%starting probe position in the non training array
c2o_params.test_count=ceil(numel(c2o_params.non_trains)*0.5);
c2o_params.current_probe_position=c2o_params.test_count+1;

%allocate rest to the dynamically adding probes.
params.idxtest=c2o_params.non_trains(1:c2o_params.current_probe_position-1);

KernelXCRC_VIPER(c2o_params,params);



end