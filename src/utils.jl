using Random:randperm, seed!, shuffle!
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
function get_ERDS(x, fs=128)
    # # DEBUG: println
    # println("size of epoch: $(size(x)) [trials x samples]")
    S = spectrogram(x[1,:], fs, 56, fs=fs, window=hanning)

    # # DEBUG:
    # println("Size of spectrogram: $(size(S.power))")

    tf_maps = zeros(Float64, size(x)[1], size(S.power)...) # trials x frequency x time
    for i in 1:size(x)[1]
        s = x[1,:]
        # tf_maps[i,:,:] = amp2db.(abs2.(stft(s, fs, 56, fs=fs, window=hanning)))
        p = spectrogram(s, fs, 56, fs=fs, window=hanning).power
        tf_maps[i,:,:] = abs2.(p)
    end

    # #DEBUG:
    # println("size of tf_map: $(size(tf_maps)) [trials x frequency x time]")

    b_mask = -2 .<= [i-3 for i in S.time] .<= -1  # mask out the values not in the time baseline

    # TODO: baseline should be mean across trials?
    s_base = tf_maps[:,:,b_mask] # select
    s_base = dropdims(mean(s_base, dims=(3)), dims=(3))

    # println("Size of baseline: $(size(s_base)) [trials x freq]")

    maps = mapslices(x-> x./s_base .- 1, tf_maps, dims=(1,2))
    # # DEBUG println
    # println("size of maps: $(size(maps))")

    return maps
end


function perm_test(X, b=1024)
    n = length(X)
    # diff = kstest(X, Y)
    # pool = [X; Y]
    # count = 0
    # diffs = []
    for i in 1:b
        shuffle!(pool)
        diff_star = kstest(pool[1:n], pool[n:end])
        push!(diffs, diff_star)
        if abs(diff_star) >= abs(diff)
            count += 1
        end
    end
    p_value = (count+1) / (b+1)
    return diff, p_value, diffs
end
