function C2O_KernalXCRC(dataset,totN)

%setup viper mat files
setup_viper 

% loading the partitions
load(fullfile(workDir,'data',sprintf('%s_trials.mat',dataset)));

%  Loading features and partitions     

params.Iter =1;
params.saveDir = strcat('.\Graphics\',dataset,'\'); 

c2o_params.totN=totN;
c2o_params.iter_id=7;
c2o_params.dataset='viper';


%allocate first half of images to the training
c2o_params.idxtrain=trials(c2o_params.iter_id).labelsAtrain;

%allocate second half to the non training
c2o_params.non_trains=trials(c2o_params.iter_id).labelsAtest;


%current_probe and gallery set initializing
c2o_params.test_start_point=ceil(numel(c2o_params.non_trains)*0.5);
c2o_params.gallery_count=ceil(numel(c2o_params.non_trains)*0.5);
c2o_params.idxtest_probe=c2o_params.non_trains(10:20);
c2o_params.idxtest_gallery=c2o_params.non_trains(1:c2o_params.gallery_count);

test_Iter_size=numel(c2o_params.non_trains)- c2o_params.test_start_point;
false_match_threshold_final_response=zeros(1,test_Iter_size);

iter=1;
%calculate false match rejection threshold

for i=c2o_params.test_start_point:numel(c2o_params.non_trains)-1
    
    c2o_params.gallery_count=i;
    c2o_params.idxtest_gallery=c2o_params.non_trains(1:i);
    c2o_params.idxtest_probe=c2o_params.non_trains(i+1);
    result=KernelXCRC_VIPER(c2o_params,params);
    index = find(result >c2o_params.test_start_point);
    if(numel(index)==0)
        false_match_threshold_final_response(i-c2o_params.test_start_point+1)=10000;        
    else
        false_match_threshold_final_response(i-c2o_params.test_start_point+1)=min(index);
    end
    
end

save('KernalXCRC_2Folder_out','false_match_threshold_final_response');

threshold=min(false_match_threshold_final_response);
%response_final=zeros(numel(c2o_params.non_trains),numel(c2o_params.non_trains));

%%get aggr_results for tests
% for i=c2o_params.test_start_point:numel(c2o_params.non_trains)
%     
%     c2o_params.gallery_count=i;
%     c2o_params.idxtest_gallery=c2o_params.non_trains(1:i);
%     c2o_params.idxtest_probe=c2o_params.non_trains(1:i);
%     result=KernelXCRC_VIPER(c2o_params,params);
%     for j=1:i
%         response_final(i-test_Iter_size+1,result(j,:)==j) = response_final(i-test_Iter_size+1,result(j,:)==j) + 1; 
%     end
%     
% end


end