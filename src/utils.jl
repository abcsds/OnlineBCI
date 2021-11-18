using Random:randperm, seed!
using Statistics:mean, std, cov  # Some statistical functions
using Plots  # Plotting library
using HypothesisTests: MannWhitneyUTest, pvalue
using DSP


"""
    x_lda(X, Y; K=10)

Cross-validated LDA for X features and Y labels.

# Examples
```julia
avgs = []
for i in 1:10
    avg = x_lda(X,Y);
    push!(avgs, avg);
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

"""
    bpfilter(x)

Bandpass filter a 1D signal from 3.5 to 35hz with a zero-phase 4th order Butterworth
# Examples
```julia
filt_buf = mapslices(bpfilter, buf; dims=2)
```
"""
function bpfilter(x)
  responsetype = Bandpass(3.5, 35; fs=128) # TODO: static frequency
  designmethod = Butterworth(4)
  filtfilt(digitalfilter(responsetype, designmethod), x)
end

"""
    l_deriv(X)

Laplacian derivation of X matrix (N * 16 chs)
# Examples
```julia
examples
```
"""
function l_deriv(X)
    M = [-.25 0    0   ;  # In: ch 1
         0    0    0   ;  # In: ch 2
         0    -.25 0   ;  # In: ch 3
         0    0    0   ;  # In: ch 4
         0    0    -.25;  # In: ch 5
         -.25 0    0   ;  # In: ch 6
         1    0    0   ;  # In: ch 7
         -.25 -.25 0   ;  # In: ch 8
         0    1    0   ;  # In: ch 9
         0    -.25 -.25;  # In: ch 10
         0    0    1   ;  # In: ch 11
         0    0    -.25;  # In: ch 12
         -.25 0    0   ;  # In: ch 13
         0    -.25 0   ;  # In: ch 14
         0    0    -.25;  # In: ch 15
         0    0    0   ;  # In: ch 16
         # Out: chs, 7, 9, 11.
         ]
  return X*M
end

"""
    get_ERDS(x)

Calculate ERDS maps from `x` epochs. Epochs are ordered as [trials x samples].
This function increases one dimension: [trials x freqs x timestamps
# Examples
```julia
examples
```
"""
function get_ERDS(x)
    S = spectrogram(x[1,:], 128, 56, fs=128, window=hanning)
    tf_maps = zeros(Float64, size(x)[1], size(S.power)...)
    for i in 1:size(x)[1]
        s = x[i,:]
        # tf_maps[i,:,:] = amp2db.(abs2.(stft(s, 128, 56, fs=fs, window=hanning)))
        tf_maps[i,:,:] = abs2.(stft(s, 128, 56, fs=fs, window=hanning))
    end

    b_mask = -2 .<= [i-3 for i in S.time] .<= -1  # mask out the values not in the baseline time
    s_base = mapslices(x-> x.*b_mask, tf_maps, dims=3) # spectrum baseline
    s_base = dropdims(mapslices(mean, s_base, dims=(1,3)), dims=(1,3)) # one value per frequency
    # FIXME: `BoundsError: attempt to access 3×65×0 Array{Float64, 3} at index [1, 1:65, 1]`
    maps = mapslices(x-> x./s_base .- 1, tf_maps, dims=2)
    # pvals = mapslices(x -> pvalue(MannWhitneyUTest(x, s_base)), erds_maps, dims=1)
    # dropdims(pvals, dims=1)

    return maps
end
