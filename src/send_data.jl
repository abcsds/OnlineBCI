#!/usr/local/bin/julia
using LSL

function main(name, uid)
    # Set parameters
    channels =  ["FC3", "FC1", "FCz", "FC2", "FC4", "C5", "C3", "C1",
                "Cz", "C2", "C4", "C6", "CP3", "CPz", "CP4", "Pz"]
    nchs = length(channels)
    fs = 128.0  # Sample frequency in hz

    # Create new stream info
    info = LSL.StreamInfo(name=name,
                          type="EEG",
                          nominal_srate=fs,
                          channel_count=nchs,
                          channel_format=Float32,
                          source_id=uid);

    # Add meta-data fields to stream info
    d = desc(info)
    append_child_value(d, "manufacturer", "LSL")
    chns = append_child(d,"channels")
    for c in 1:nchs
        chn = append_child(chns,"channel")
        append_child_value(chn,"label",channels[c])
        append_child_value(chn,"unit","microvolts")
        append_child_value(chn,"type","EEG")
    end

    # Create a new outlet (chunking: default, buffering: 360 seconds)
    outlet = StreamOutlet(info,chunk_size=0, max_buffered=360);

    println("Waiting for consumers...")
    while wait_for_consumers(outlet, 120) == 0
        sleep(0.1)
    end
    println("Client connected!")

    # Send data until the last consumer has disconnected
    println("Now sending data...")
    lt = time()
    # cursample = zeros(Float32, nchs)
    while have_consumers(outlet) != 0
        t = time()
        dt = t-lt
        if dt >= (1. / fs) # Regular sampling frequency
            # cursample .+= (randn(Float32, nchs)*10) # smooth out noise
            push_sample(outlet,(randn(Float32, nchs)*50));
            lt = t
        end
    end

    println("Lost the last consumer, shutting down")
    # close_stream(outlet);
end

println("send_data.jl: sends 16 float channels at 128hz")
println("Usage: send_data.jl [fs] [streamname] [streamuid] ")
# println("Using lsl $(LSL.library_version()), lsl_library info: $(unsafe_string(LSL.library_info()))")

const name = length(ARGS) > 0 ? ARGS[1] : "send_data"
const uid = length(ARGS) > 1 ? ARGS[2] : "42saontehu42"

main(name, uid)
