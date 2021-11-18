using XDF

streams = read_xdf("raw/000.xdf")
n_streams = length(streams)

ms = ds = None # Marker and Data Stream numbers
for sn in range(n_streams):
    if streams[sn]["info"]["name"][0] == 'PsychoPy':
        ms = sn
    if streams[sn]["info"]["type"][0] == 'EEG':
        ds = sn
    else:
        continue
