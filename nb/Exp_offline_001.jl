using XDF
using Plots
include("./utils.jl")

fname = "raw/000.xdf"

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
m_ix = argmin.([abs.(d_ts.-i) for i in m_ts]) # TODO: benchmark and optimize
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
# println("Derived epochs size: $(size(epochs_d)) [Trials x Samples x Nchs]")

for ch in 1:nchs
	epochs_d[:,:,ch]
erds_maps = mapslices(get_ERDS, epochs_d; dims=(1,2))

printlnt("Size of ERDS maps: $(size(erds_maps)) []")
