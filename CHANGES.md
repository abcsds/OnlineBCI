# 22.10.2021
Create project from template

# 18.11.2021
Update training protocol. Add examples from julia LSL library for online decoding. Add offline processing script. Add utilites.

# 25.11.2021
Add real data example file `001.xdf`.
Update ERDS maps for debugging.
Add permutation test utility.

# 31.01.2021
After vacations and finishing the course this project was origially made for, progress for this specific repo might be slow. Here are some notes to pick it up:
`000.xdf` was recorded with the psychopy paradigm, but no subject. It thus contains markers, and random noise. It is enough to train a useless CSP and sLDA model.
Training seemed to be working, but ERDS maps don't, so no frequency band selection can be done yet.
A subject was measured and the file `001.xdf` contains their data.
TODO:
- Implement ERDS maps as in Faller 2012.
- Run offline script with subject file.
- Verify model accuracy and feature separability.
- Retrain model with selected features.
- Create online script that applies offline model and online feedback about the classifier.

# 02.02.2022
Offline analysis does not work with file `001`. An exploration julia file was created as a notebook to be run with Atom's Juno environment.

Julia libraries:
```
XDF
IJulia
Plots
HypothesisTests
DSP
```

ERROR: garbage collector throws an error and closes julia every time it runs. This is only reproducible in Office computer.
