using Random:randperm, seed!
using Statistics:mean, std, cov  # Some statistical functions
using Plots  # Plotting library
using HypothesisTests: MannWhitneyUTest, pvalue


"""
    x_lda(X, Y; K=10)

Cross-validated LDA for X features and Y labels.

# Examples
```julia
avgs = []
for i in 1:10
    avg = x_lda(X,Y);
    push!(avgs, avg);
    println("Accuracy run $(i): $(avg)")
end
```
"""
function x_lda(X,Y,K=10)
    N = size(X,1)
    stops = round.(Int,[range(1,stop=N,length=K+1);])
    splits = [s:e-(e<N)*1 for (s,e) in zip(stops[1:end-1],stops[2:end])]
    idx = randperm(N);
    accs = [];
    for i in 1:K
        # Dataset splitting
        X_val = X[idx[splits[i]],:]
        Y_val = Y[idx[splits[i]],:]
        X_trn = vcat([X[idx[splits[j]],:] for j in 1:K if j != i]...)
        Y_trn = vcat([Y[idx[splits[j]],:] for j in 1:K if j != i]...)

        # LDA fitting
        mu1 = mean(X_trn[vec(Y_trn.==0),:], dims=1);
        mu2 = mean(X_trn[vec(Y_trn.==1),:], dims=1);
        sg = cov(X_trn);
        w = 2 * (mu2 - mu1) * inv(sg);
        p1 = sum(Y_trn) / size(Y_trn,1);
        p2 = 1-p1;
        b = (mu1 - mu2) * inv(sg) * (mu1 - mu2)' .+ 2*log(p2/p1)

        # LDA predicting
        y_hat = (sign.(X_val * w' .+ b) .== 1);
        acc = sum(Y_val .== y_hat)/length(y_hat);
        push!(accs, acc);
    end
    mean(accs)
end
