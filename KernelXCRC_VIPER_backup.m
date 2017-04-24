function KernelXCRC_VIPER_backup

close all


workDir = pwd;
dataset ='viper';


load(fullfile(workDir,'data',sprintf('%s_trials.mat',dataset)));
load(fullfile(workDir,'data',sprintf('%s_features.mat',dataset)));

params.N = 316;    
% Parameters
params.scale =8e-1;
params.lambda = 1e-2; 

params.saveDir = strcat('.\Graphics\',dataset,'\'); 

answer={};legend={};

                      
                
params.Iter =10;
resp = zeros(1,params.N);    
rng(10);

final_resp=zeros(params.Iter,numel(trials(1).labelsAtest));

%for iter=1:params.Iter
   
    iter=1;
    % (1) Loading features and partitions         
    params.idxtrain = trials(iter).labelsAtrain;
    params.idxtest = trials(iter).labelsAtest;
   
    params.N = 632;
    % subtracting the minimum
    dt = bsxfun(@minus,features, min(features,[],1));

    feat.dataA = dt(params.idxtrain,:); feat.dataB = dt(params.idxtrain + params.N,:); 
    test_feat.dataA = dt(params.idxtest,:);  test_feat.dataB = dt(params.idxtest + params.N,:);  

    
    % Extracting XQDA features (I modify lambda to 1e-4 due the WHOS)
    [W, ~] = XQDA(feat.dataB, feat.dataA, (1:size(feat.dataB,1))', (1:size(feat.dataA,1))'); 
    xQDA_feat.dataA = feat.dataA*W;  xQDA_feat.dataA = normr(xQDA_feat.dataA); 
    xQDA_feat.dataB = feat.dataB*W;  xQDA_feat.dataB = normr(xQDA_feat.dataB); 
    test_xQDA_feat.dataA = test_feat.dataA*W; test_xQDA_feat.dataA = normr(test_xQDA_feat.dataA);
    test_xQDA_feat.dataB = test_feat.dataB*W; test_xQDA_feat.dataB = normr(test_xQDA_feat.dataB);

   

    % RBF-KERNEL (nonlinear mapping)
    train_a_ker = rbf(xQDA_feat.dataA ,xQDA_feat.dataA,params.scale); 
    test_a_ker =  rbf(test_xQDA_feat.dataA ,xQDA_feat.dataA,params.scale);
    train_b_ker = rbf(xQDA_feat.dataB ,xQDA_feat.dataB,params.scale); 
    test_b_ker =  rbf(test_xQDA_feat.dataB ,xQDA_feat.dataB,params.scale);
    
    % ----------------- Kernel X-CRC Method --------------------
    
    % Kernel X-CRC (as described in the Algorithm 1) 
    Model = Kernel_XCRC(train_a_ker,train_b_ker, params);

     for i=1:numel(params.idxtest) % For each probe
        fprintf('Processing image %d \n',i);
        alfa_error = zeros(1,numel(params.idxtest));     

        dX = Model.AlfaX.BetaX*test_a_ker(i,:)';
        dY = Model.AlfaY.BetaX*test_a_ker(i,:)';
        for n=1:numel(params.idxtest) % For each gallery
            alfax =  dX + Model.AlfaX.BetaY*test_b_ker(n,:)';
            alfay =  dY + Model.AlfaY.BetaY*test_b_ker(n,:)';
            % computing the cosine distance between coding vectors
            alfa_error(n) = pdist2(alfax',alfay','cosine');
        end
        [~,idx_error(i,:)] = sort(alfa_error,'ascend');
    end
    resp = zeros(1,size(test_b_ker,1));
   
    for i=1:numel(params.idxtest) % For each probe
         resp(idx_error(i,:)==i) = resp(idx_error(i,:)==i) + 1;
         final_resp(iter,idx_error(i,:)==i) = final_resp(iter,idx_error(i,:)==i) + 1;
    end
    
    toc
    
   
%end


end


% rbf-chi-square kernel
function Z = rbf(X,Y,varargin)
if numel(varargin) == 0
    sigma = 1;
else
    sigma = varargin{1};
end
nX = size(X,1);
nY = size(Y,1);
Z = zeros(nX,nY);

n1sq = sum(X.^2,2);
n2sq = sum(Y.^2,2);

part1=n1sq*ones(1,nY);
part2=n2sq*ones(1,nY);
part3=-2*X*Y';
D=part1+part2+part3;
Z = exp(-D/(2*sigma^2));

end

function Model = Kernel_XCRC(KX,KY,params)
    % Kernel X-CRC function (refer to the paper for more details). 
    % Kx and Ky are obtained applying the kernel function in training data from both cameras (n x n matrices)
   
    n = size(KX,2);
    % Equation 7
    Px = inv(KX + (params.lambda + 1)*eye(n));
    Py = inv(KY + (params.lambda + 1)*eye(n));
    
    % Equation 9 and 11, respectively.
    Q = inv(eye(n) -  Py*Px);
    W = inv(eye(n) -  Px*Py);
    
    % Computing the projection matrices (see Algorithm 1)
    % BetaY
    Model.AlfaY.BetaX = Q*Py*Px;
    Model.AlfaY.BetaY = Q*Py;
    % BetaX
    Model.AlfaX.BetaX = W*Px;
    Model.AlfaX.BetaY = W*Px*Py;
end

function [W, M, inCov, exCov] = XQDA(galX, probX, galLabels, probLabels, options)
    %% function [W, M, inCov, exCov] = XQDA(galX, probX, galLabels, probLabels, options)
    % Cross-view Quadratic Discriminant Analysis for subspace and metric
    % learning
    
    % Reference:
    %   Shengcai Liao, Yang Hu, Xiangyu Zhu, and Stan Z. Li. Person
    %   re-identification by local maximal occurrence representation and metric
    %   learning. In IEEE Conference on Computer Vision and Pattern Recognition, 2015.
    
    lambda = 0.0001;
    qdaDims = -1;
    verbose = false;

    if nargin >= 5 && ~isempty(options)
        if isfield(options,'lambda') && ~isempty(options.lambda) && isscalar(options.lambda) && isnumeric(options.lambda)
            lambda = options.lambda;
        end
        if isfield(options,'qdaDims') && ~isempty(options.qdaDims) && isscalar(options.qdaDims) && isnumeric(options.qdaDims) && options.qdaDims > 0
            qdaDims = options.qdaDims;
        end
        if isfield(options,'verbose') && ~isempty(options.verbose) && isscalar(options.verbose) && islogical(options.verbose)
            verbose = options.verbose;
        end
    end

    if verbose == true
        fprintf('options.lambda = %g.\n', lambda);
        fprintf('options.qdaDims = %d.\n', qdaDims);
        fprintf('options.verbose = %d.\n', verbose);
    end

    [numGals, d] = size(galX); % n
    numProbs = size(probX, 1); % m

    % If d > numGals + numProbs, it is not necessary to apply XQDA on the high dimensional space. 
    % In this case we can apply XQDA on QR decomposed space, achieving the same performance but much faster.
    if d > numGals + numProbs
        if verbose == true
            fprintf('\nStart to apply QR decomposition.\n');
        end

        t0 = tic;
        [W, X] = qr([galX', probX'], 0); % [d, n]
        galX = X(:, 1:numGals)';
        probX = X(:, numGals+1:end)';
        d = size(X,1);
        clear X;

        if verbose == true
            fprintf('QR decomposition time: %.3g seconds.\n', toc(t0));
        end
    end


    labels = unique([galLabels; probLabels]);
    c = length(labels);

    if verbose == true
        fprintf('#Classes: %d\n', c);
        fprintf('Compute intra/extra-class covariance matrix...');
    end

    t0 = tic;

    galW = zeros(numGals, 1);
    galClassSum = zeros(c, d);
    probW = zeros(numProbs, 1);
    probClassSum = zeros(c, d);
    ni = 0;

    for k = 1 : c
        galIndex = find(galLabels == labels(k));
        nk = length(galIndex);
        galClassSum(k, :) = sum( galX(galIndex, :), 1 );

        probIndex = find(probLabels == labels(k));
        mk = length(probIndex);
        probClassSum(k, :) = sum( probX(probIndex, :), 1 );

        ni = ni + nk * mk;
        galW(galIndex) = sqrt(mk);
        probW(probIndex) = sqrt(nk);
    end

    galSum = sum(galClassSum, 1);
    probSum = sum(probClassSum, 1);
    galCov = galX' * galX;
    probCov = probX' * probX;

    galX = bsxfun( @times, galW, galX );
    probX = bsxfun( @times, probW, probX );
    inCov = galX' * galX + probX' * probX - galClassSum' * probClassSum - probClassSum' * galClassSum;
    exCov = numProbs * galCov + numGals * probCov - galSum' * probSum - probSum' * galSum - inCov;

    ne = numGals * numProbs - ni;
    inCov = inCov / ni;
    exCov = exCov / ne;

    inCov = inCov + lambda * eye(d);

    if verbose == true
        fprintf(' %.3g seconds.\n', toc(t0));
        fprintf('#Intra: %d, #Extra: %d\n', ni, ne);
        fprintf('Compute eigen vectors...');
    end


    t0 = tic;
    [V, S] = svd(inCov \ exCov);

    if verbose == true
        fprintf(' %.3g seconds.\n', toc(t0));
    end

    latent = diag(S);
    [latent, index] = sort(latent, 'descend');
    energy = sum(latent);
    minv = latent(end);

    r = sum(latent > 1);
    energy = sum(latent(1:r)) / energy;

    if qdaDims > r
        qdaDims = r;
    end

    if qdaDims <= 0
        qdaDims = max(1,r);
    end

    if verbose == true
        fprintf('Energy remained: %f, max: %f, min: %f, all min: %f, #opt-dim: %d, qda-dim: %d.\n', energy, latent(1), latent(max(1,r)), minv, r, qdaDims);
    end

    V = V(:, index(1:qdaDims));
    if ~exist('W', 'var');
        W = V;
    else
        W = W * V;
    end

    if verbose == true
        fprintf('Compute kernel matrix...');
    end

    t0 = tic;

    inCov = V' * inCov * V;
    exCov = V' * exCov * V;
    M = inv(inCov) - inv(exCov);

    if verbose == true
        fprintf(' %.3g seconds.\n\n', toc(t0));
    end
end