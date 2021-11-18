using LSL
# using SampledSignals
using DSP
import Statistics: mean


n_chans = 16
sfreq = 128
buffer_size = 8*sfreq

function process_buf(buf)
  buf = mapslices(bpfilter, buf; dims=2)
  # println(size(buffer))
  println(mean(buffer))
end

function bpfilter(x)
  responsetype = Bandpass(3.5, 35; fs=sfreq)
  designmethod = Butterworth(4)
  filtfilt(digitalfilter(responsetype, designmethod), x)
end

println("Searching for streams...")
d_stream = resolve_byprop("name", "g.USBamp-1", timeout=10.0)
@assert length(d_stream) == 1
m_stream = resolve_byprop("name", "gUSBamp-1Markers", timeout=10.0)
@assert length(m_stream) == 1


data_inlet = StreamInlet(d_stream[1])
open_stream(data_inlet)
mark_inlet = StreamInlet(m_stream[1])
open_stream(mark_inlet)

l = Float64[]
buffer = Array{Float32}(undef, (n_chans, buffer_size))
last = 0.0
count = 0.0
while true
  global buffer, , sfreq, last, count, l
  local ts, samp

  if Bool(samples_available(mark_inlet))
    ts, mark = pull_sample(mark_inlet, timeout=1.0)
  end

  if Bool(samples_available(data_inlet))
    ts, samp = pull_sample(, data_inlet, timeout=1.0)
    buffer = [buffer[:,2:end] samp]
    # TODO: markers?
    dt = (ts - last)
    count += dt
    if count >= 1 # buffer evaluation period (in seconds)
      err = (1. - count) * -1000
      push!(l, err)
      println("Nominal sfreq: $(1. / dt) error (ms):$(err)")
      process_buf(buffer)
      count = 0.0
    end
    last = ts
  else
    continue
  end
end
close_stream(data_inlet)


using Plots, StatsPlots
mean(l)
density(l)
