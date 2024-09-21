function subX = ZS_getSubsample(uq_input,level,N)
warning('off','stats:kmeans:FailedToConverge')
X    = uq_getSample(uq_input,10^4);
fX   = uq_evalPDF(X,uq_input);
idx  = fX >= level;
X    = X(idx,:);
subX = uq_subsample(X,N,'k-means');
end