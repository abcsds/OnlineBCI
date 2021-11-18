using XDF
using Plots
include("./utils.jl")

function main(fname::String)
    streams = read_xdf(fname)
    n_streams = length(streams)
    ms = ds = 0 # Marker and Data Stream numbers
    for sn in 1:n_streams
        if streams[sn]["name"] == "PsychoPy"
            ms = sn
        elseif streams[sn]["name"] == "send_data"
        # elseif streams[sn]["name"] == "g.USBamp-1"
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

    # epoching
    w = (-3, 5) # Window
    marker = m_ix[1]
    r = marker+Int(w[1]*fs) : marker+Int(w[2]*fs)-1
    epochs = zeros(Float64, length(m_ix), length(r), nchs)
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
    erds_maps = mapslices(get_ERDS, epochs_d; dims=(3))

    #


end
main("raw/000.xdf")

# hardcode
streams = read_xdf("raw/000.xdf")
ds = 2
ms = 1


### ERDS maps

x = epochs_d[:,:,1]
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
maps = mapslices(x-> x./s_base .- 1, tf_maps, dims=2)
# pvals = mapslices(x -> pvalue(MannWhitneyUTest(x, s_base)), erds_maps, dims=1)


### power spectrum
