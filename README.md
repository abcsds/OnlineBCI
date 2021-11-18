# Online BCI

An online BCI based on motor imagery.

## Method

The goal of this project is to build an online BCI for two classes: Motor Imagery (MI) of hand, and feet movement.

### Training
A paradigm for recording data. The data recorded with this paradigm will be used to create a preprocessing pipeline, and train an ML model.

The model is later tested with an online decoder against the same paradigm, comparing paradigm markers to online decoder output.

### Montage
Montage reference under `doc/settings/electrodes_NBCI2.pdf`. Composed of 16 electrodes:
```
 [
  "FC3",
  "FC1",
  "FCz",
  "FC2",
  "FC4",
  "C5",
  "C3",
  "C1",
  "Cz",
  "C2",
  "C4",
  "C6",
  "CP3",
  "CPz",
  "CP4",
  "Pz",
 ]
```

### Preprocessing

#### Offline
1. Filtering Bandpass 0.3 to 35, zero-phase Butterworth 4th order.
2. Artifact-dealing and trial rejection.
3. Laplacian derivations C3, Cz, C4.
4. ERD/S maps and PSD visualization.

### Classification
An sLDA is used to classify the two classes.

PSD `window_size = fs` overlap of 50%
Results in DB (`20*log10*(x)`)
ERD/S maps, baseline (-2, -1) analysis window (-3, 5)
Frequency bands: [(4,8), (6,10), ..., (24,28), (26,30)]

CSP for feature extraction

Posible to downsample.

2/3 training 1/3 validation: 80 train 40 validation
10x 5fold CV with training set.

Validation accuracy.

Select a maximum of 8 features to train sLDA.


## Project Folder structure
- `data`: a folder to keep the input data for your experiment. These are stimuli, images, videos, sounds, etc., for your paradigm. Datasets for non-recording experiments can be placed here.
- `doc`: Documentation for your research project.
 - `handouts`: Documents to hand out to your participants. This includes a Call for Participants, and an information sheet for the participants.
 - `img`: Figures, images, and plots that help you document your experiment.
 - `settings`: Place your settings or configuration files here.
  - `BrainVisionRecorder`: Workspace and configurations for BP software. An example of a workspace file for BVRecorder is placed here.
  - `layout`: Files related to the electrode placement selected.
- `raw`: This folder contains the `XDF` files required for analysis.
- `para`: The psychopy paradigm folder.
 - `data`: A folder for the logs comming from psychopy.
 - `lists`: The trial lists for the paradigm.
 - `res`: A folder for the resources of your paradigm.
 - `main.psyexp`: The RSVP paradigm programmed for psychopy.
 - `README.md`: Information on the paradigm project.
- `scr`: Scripts for processing and analysis.

## Raw Data
Raw data is stored in the [`xdf`](https://github.com/sccn/xdf/wiki/Specifications) format, under the `out` directory.

Subject 000 is no subject (just noise).
