function C2O(dataset,totN)

workDir=pwd;

%load trials
load(fullfile(workDir,'data',sprintf('%s_trials.mat',dataset)));

%load viper features
workDir=pwd;
load(fullfile(workDir,'data',sprintf('%s_features.mat',dataset)));

params.Iter =1;
params.saveDir = strcat('.\Graphics\',dataset,'\'); 
c2o_params.totN=totN;
c2o_params.iter_id=1;
c2o_params.dataset='viper';
c2o_params.idxtrain=trials(c2o_params.iter_id).labelsAtrain; %316 for viper trains
c2o_params.non_trains=trials(c2o_params.iter_id).labelsAtest; %316 for viper non trains


%let 200 for randoms
%current_probe and gallery set initializing
%define k/10 as the precentage of duplicate samples
%ex ; k=2 means 20 humans have been re appeared to the camera from the total of 100 inputs
c2o_params.two_folder_point=200;
c2o_params.input_sample_size=100;

for k=3:4
    
    c2o_params.duplicate_feed_size=(c2o_params.input_sample_size*k)/10;
    
   
    %final_outs
    respons_false_match=zeros(10,4);
    respons_re_id=zeros(10,2);

    

    for threshold=1:10        
        
        %set starting points
        c2o_params.idxtest_gallery=c2o_params.non_trains(1:c2o_params.two_folder_point);
        c2o_params.input_array_unshuffled=c2o_params.non_trains(c2o_params.two_folder_point+1:c2o_params.two_folder_point+c2o_params.input_sample_size);
        repeat_feed=c2o_params.input_array_unshuffled(c2o_params.duplicate_feed_size+1:2*c2o_params.duplicate_feed_size); 
        c2o_params.input_array_unshuffled(1:c2o_params.duplicate_feed_size)=repeat_feed;
        c2o_params.probe_cam=1;
        ix = randperm(numel(c2o_params.input_array_unshuffled));
        c2o_params.input_array = c2o_params.input_array_unshuffled(ix);
        
        tic
        
        CORRECT_NEW_COUNT=0;
        FALSE_NEW_COUNT=0;
        CORRECT_RE_IDENTIFICATION_COUNT=0;
        FALSE_RE_IDENTIFICATION_COUNT=0;
        MISSED_TRUE_NEW=0;
        CORRECT_RE_APPEARANCE_COUNT=0;        
        TOTAL_INPUT_COUNT=numel(c2o_params.input_array);

        for i=1:numel(c2o_params.input_array)

        %parameter setup for iteration
        c2o_params.probe_cam=1;
        index=find(c2o_params.input_array==c2o_params.input_array(i));
        if(index(1) ~= i)
             c2o_params.probe_cam=2;
        end
        c2o_params.idxtest_probe=c2o_params.input_array(i);


        %evaluate iteration results
        raw_result=KernelXCRC_VIPER(c2o_params,params,features); 
        result=raw_result(1:threshold);
        possible_matches = find(result >c2o_params.two_folder_point);
        if(numel(possible_matches)==0)
            matched_id=-1;     
        else   
            matched_id=result(possible_matches(1));
        end

        if(matched_id == -1)
            %identified as a new person
            if(c2o_params.probe_cam==2)
                FALSE_NEW_COUNT=FALSE_NEW_COUNT+1;
            else
                CORRECT_NEW_COUNT=CORRECT_NEW_COUNT+1;
            end

            c2o_params.idxtest_gallery =[c2o_params.idxtest_gallery c2o_params.input_array(i)];

        else
            if(index(1) ~= i)
                CORRECT_RE_APPEARANCE_COUNT=CORRECT_RE_APPEARANCE_COUNT+1;
            else
                MISSED_TRUE_NEW=MISSED_TRUE_NEW+1;
            end

            if(index(1) ~= i)
                if(c2o_params.idxtest_probe==c2o_params.idxtest_gallery(matched_id))
                    %re-identified as the correct person - TRUE_POSITIVE
                    %do nothing to gallery
                    CORRECT_RE_IDENTIFICATION_COUNT=CORRECT_RE_IDENTIFICATION_COUNT+1;
                else 
                    %re-identified as a wrong person - FALSE_POSITIVE
                    %do nothing to gallery           
                    FALSE_RE_IDENTIFICATION_COUNT=FALSE_RE_IDENTIFICATION_COUNT+1;
                end       
            end
        end

        end

        respons_false_match(threshold,1)= CORRECT_NEW_COUNT;
        respons_false_match(threshold,2)= FALSE_NEW_COUNT;
        respons_false_match(threshold,3)= MISSED_TRUE_NEW;
        respons_false_match(threshold,4)= CORRECT_RE_APPEARANCE_COUNT;
        respons_re_id(threshold,1)= CORRECT_RE_IDENTIFICATION_COUNT;
        respons_re_id(threshold,2)= FALSE_RE_IDENTIFICATION_COUNT;
        
        toc
        fprintf('Test completed for threshold = %s \n',num2str(threshold))
    end

    response_precentages=respons_false_match/TOTAL_INPUT_COUNT;
    save(strcat('respons_false_match_',num2str(k)),'respons_false_match');
    save(strcat('response_precentages_',num2str(k)),'response_precentages');
    save(strcat('respons_re_id_',num2str(k)),'respons_re_id');

end

end