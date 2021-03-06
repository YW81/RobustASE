
clear all
close all

%% --- Parameters Setting ---
epsilon = 0.1;
epsilonInB = 0.05;
ratio = 2;

m = 10;
nVertex = 150;
nBlock = 3;
theta = ones(1, nBlock);
dimLatentPosition = nBlock;
rho = repmat(1/nBlock, 1, nBlock);
iStart = 1;
iEnd = 100;

scale = 1;


% block probability matrix
B = (0.5 - epsilonInB)*ones(nBlock, nBlock) + 2*epsilonInB*eye(nBlock);
B = scale^2*B;

% true nu (nBlock-by-dimLatentPosition)
% nuStar = chol(B)';
[U, S, ~] = svds(B, dimLatentPosition);
nuStar = U*sqrt(S);

% true spectral graph embedding Xhat (nBlock-by-dimLatentPosition)
xHatHL = asge(B, dimLatentPosition);

%% --- Parallel Computing ---
% delete(gcp('nocreate'))
% parpool(nCore);


%% Monte Carlo Simulation

% errorRate = zeros(1, m);
% errorRate1 = zeros(1, m);
% errorRate2 = zeros(1, m);
% for l = 5:m

errorRateMean = zeros(1, iEnd);
errorRateHL = zeros(1, iEnd);
ADiffMean = zeros(1, iEnd);
ADiffHL = zeros(1, iEnd);

for iIter = iStart:iEnd
    adjMatrixTotal = zeros(m, nVertex, nVertex);
    adjMatrixSum = zeros(nVertex, nVertex);
    for iGraph = ((iIter - 1)*m+1):(iIter*m)
        % Generate data if there does not exist one, otherwise read the
        % existing data.
        [adjMatrix, tauStar, xStar, ~] = datagenerator_discrete(nVertex, nBlock, ...
            dimLatentPosition, B, nuStar, rho, epsilon, scale, ratio, iGraph);
        adjMatrixTotal(iGraph - (iIter - 1)*m, :, :) = adjMatrix;
        adjMatrixSum = adjMatrixSum + adjMatrix;
    end
    
    adjMatrixMean = adjMatrixSum/m;
    adjMatrixHL = hlcalculator(adjMatrixTotal, m);
    
    % mean
    xHatMean = asge(adjMatrixMean, dimLatentPosition);
    gm = fitgmdist(xHatMean, nBlock, 'Replicates', 10);
    tauHatMean = cluster(gm, xHatMean)';
    errorRateMean(iIter) = errorratecalculator(tauStar, tauHatMean, nBlock);
    ADiffMean(iIter) = norm(xHatMean*xHatMean' - xStar*xStar');
    
    % HL
    xHatHL = asge(adjMatrixHL, dimLatentPosition);
    gm = fitgmdist(xHatHL, nBlock, 'Replicates', 10);
    tauHatHL = cluster(gm, xHatHL)';
    errorRateHL(iIter) = errorratecalculator(tauStar, tauHatHL, nBlock);
    ADiffHL(iIter) = norm(xHatHL*xHatHL' - xStar*xStar');
end

[mean(errorRateMean), mean(errorRateHL)]

% 1-sided sign-test HA errorRateMean > errorRateHL
tmpStats = sum(errorRateMean > errorRateHL);
pValue = 1 - binocdf(tmpStats - 1, iEnd, 0.5)

[mean(ADiffMean), mean(ADiffHL)]

% 1-sided sign-test
tmpStats = sum(ADiffMean > ADiffHL);
pValue = 1 - binocdf(tmpStats - 1, iEnd, 0.5)



%% --- Plot ---
% plot3(xHatMean(:, 1), xHatMean(:, 2), xHatMean(:, 3), '.')
% hold on;
% plot3(xHatHL(:, 1), xHatHL(:, 2), xHatHL(:, 3), 'r.')

%% --- Close Parallel Computing ---
% delete(gcp('nocreate'))
