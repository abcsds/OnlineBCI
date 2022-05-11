using XDF
using Plots
include("./utils.jl")


fname = "raw/001.xdf"
streams = read_xdf(fname)
n_streams = length(streams)
s_names = [stream["name"] for (k,stream) in streams]

ms = ds = 0 # Marker and Data Stream numbers
for sn in 1:n_streams
    if streams[sn]["name"] == "PsychoPy"
        ms = sn
    # elseif streams[sn]["name"] == "send_data"
    elseif streams[sn]["name"] == "g.USBamp-1"
        ds = sn
    else
        continue
    end
end
ms != ds ? nothing : throw(AssertionError("Error reading streams"))

fs   = streams[ds]["srate"]
data = streams[ds]["data"] # [N x nchs]
d_ts = streams[ds]["time"]
mrks = vec(streams[ms]["data"])
m_ts = streams[ms]["time"]
nchs = size(data)[2]

# Align markers
m_ix = argmin.([abs.(d_ts.-i) for i in m_ts])
m_ts = d_ts[m_ix]
sum(i in d_ts for i in m_ts) == length(m_ts) ? nothing : throw(AssertionError("Error aligning markers"))

# Filtering
data = mapslices(bpfilter, data; dims=1)

# Epoching
w = (-3, 5) # Window
marker = m_ix[1]
r = marker+Int(w[1]*fs) : marker+Int(w[2]*fs)-1
epochs = zeros(Float64, length(m_ix), length(r), nchs) # trials x samples x chs
for (i,marker) in enumerate(m_ix)
    r = marker+Int(w[1]*fs) : marker+Int(w[2]*fs)-1 # Trial range
    epochs[i,:,:] = data[r,:]
end

# Trial Rejection
# TODO: needs real data

# Laplacian
# data = l_deriv(data)
epochs_d = mapslices(l_deriv, epochs; dims=(2,3))

# ERD/S maps
# println("Derived epochs size: $(size(epochs_d)) [Trials x Samples x Nchs]")

x = epochs_d[:,:,1] # C3

S = spectrogram(x[1,:], 128, 56, fs=128, window=hanning)
plot(S.time .+ w[1], S.freq, S.power, ylims=(0,20), xlab="Time (s)", ylab="Frequency (Hz)", fill=true, c=:viridis)
vline!([0], c="black", lab=nothing)
title!("Spectrogram")
savefig("doc/img/Single_Spectrogram.png")


lbl = ([S.time;] .+ w[1])  .< 0
for f in 1:length(S.freq)
    A = S.power[f,:]
    R = mean(A .* bl)
    S.power[f,:] = (A .- R) ./ R
end

plot(S.time .+ w[1], S.freq, S.power,
    ylims=(0,20),
    xlab="Time (s)", ylab="Frequency (Hz)", fill=true, c=:viridis)
vline!([0], c="black", lab=nothing)
title!("ERDS map")
savefig("doc/img/Single_ERDS_map.png")



# Now for all channels
S = spectrogram(x[1,:], 128, 56, fs=128, window=hanning)
map_times = [S.time;] .+ w[1]
map_freqs = S.freq
lbl = (map_time)  .< 0
maps = zeros(Float64, length(m_ix), size(S.power)...) # trials x freqs x samples
for tr in 1:size(x, 1)
    S = spectrogram(x[tr,:], 128, 56, fs=128, window=hanning)
    for f in 1:length(S.freq)
        A = S.power[f,:]
        R = mean(A .* bl)
        maps[tr,f,:] = (A .- R) ./ R
    end
end

plot(map_time, S.freq, mean(maps, dims=1)[1,:,:], xlab="Time (s)", ylab="Frequency (Hz)", fill=true, c=:viridis)
vline!([0], c="black", lab=nothing)
title!("average ERDS map")
savefig("doc/img/AvgERDS.png")

plot(map_time, S.freq, mean(maps, dims=1)[1,:,:], ylim=(0,20), xlab="Time (s)", ylab="Frequency (Hz)", fill=true, c=:viridis)
vline!([0], c="black", lab=nothing)
title!("average ERDS map")
savefig("doc/img/AvgERDS_020.png")


p = [pvalue(MannWhitneyUTest(maps[mrks.==1,f,s], maps[mrks.==2,f,s])) for f in 1:length(map_freqs), s in 1:length(map_times)]
mask = p .<= 0.05;

plot(map_time, S.freq, mean(maps, dims=1)[1,:,:] .* mask, ylim=(0,20), xlab="Time (s)", ylab="Frequency (Hz)", fill=true, c=:viridis)
vline!([0], c="black", lab=nothing)
title!("Masked average ERDS map")
savefig("doc/img/AvgERDS_Utest.png")



