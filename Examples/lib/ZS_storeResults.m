function results = ZS_storeResults(results,mu,LOO,L1,C0,XC0,N,Degree,MaxDegree)

level = ['MU_',char(string(mu))];

results.LOO.(level)       = LOO;
results.L1.(level)        = L1;
results.C0.(level)        = C0;
results.XC0.(level)       = XC0;
results.N.(level)         = N;
results.Degree.(level)    = Degree;
results.MaxDegree.(level) = MaxDegree;
end