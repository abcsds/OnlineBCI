#!/usr/local/bin/julia
using LSL

function main(name, uid)

  # Create new stream info
  info = LSL.StreamInfo(name=name,
                        type="EEG",
                        channel_count=16,
                        channel_format=Float32,
                        source_id=uid);

  # Add meta-data fields to stream info
  d = desc(info)
  append_child_value(d, "manufacturer", "LSL")
  channels = ["C3","C4","Cz","FPz","POz","CPz","O1","O2"]
  chns = append_child(d,"channels")
  for c in 1:length(channels)
    chn = append_child(chns,"channel")
    append_child_value(chn,"label",channels[c])
    append_child_value(chn,"unit","microvolts")
    append_child_value(chn,"type","EEG")
  end

  # Create a new outlet (chunking: default, buffering: 360 seconds)
  outlet = StreamOutlet(info,chunk_size=0, max_buffered=360);

  println("Waiting for consumers")
  while wait_for_consumers(outlet, 120) == 0
    sleep(0.1)
  end

  println("Now sending data...")

  # Send data until the last consumer has disconnected
  t = 0
  cursample = zeros(Float32, 8)

  while have_consumers(outlet) != 0
    cursample[1] = t;
    for c in 2:8
      cursample[c] = Float32.((rand()%1500)/500.0-1.5);
    end
    push_sample(outlet,cursample);
    t += 1
  end

  println("Lost the last consumer, shutting down")
  # close_stream(outlet);

end

println("lib_send_data example program: sends 8 float channels as fast as possible")
println("Usage: lib_send_data.jl [streamname] [streamuid]")
# println("Using lsl $(LSL.library_version()), lsl_library info: $(unsafe_string(LSL.library_info()))")

const name = length(ARGS) > 0 ? ARGS[1] : "send_data_lib"
const uid = length(ARGS) > 1 ? ARGS[2] : "325wqer4354"

main(name, uid)
