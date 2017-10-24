# Scalar-MET-Signatures
# From scalar models to pheno signatures

# First time setup

To get the code:
```
git clone git@github.com:DonatasZaripovas/Scalar-MET-Signatures.git
cd Scalar-MET-Signatures
```
Now to get the relevant packages run 
```
source bootstrap.sh
```
# Bootstrap explanation
This should detect if you have a MadGraph software installed and prompt you to install it if you do not have it.
Currently tested on MacOS and Linux distributions. If MadGraph is detected, paths are set for the $MG5Path/models/ directory
for implementing new models. The Example model (inside Example_UFO) is copied to this directory so that mg5 can access it.

Next an interface with Pythia8 should be setup (also prompted), which allows direct .lhe -> .hepmc event shower.
You can change the Pythia card by passing extra parameters to the runmodel.py python file.
By default a custom Pythia card is passed (in run_mg5/Pythia8_cards) and Jet matching is turned on.
You can also choose the decay of tops in the runmodel.py script, available options: Hadronic, Semileptonic, Leptonic or "" (i.e. no decay)

Choose 
```
doMG5 = True
```
to run MG5.

Next rivet installation will be asked for rivet analysis, if rivet is not detected in current $PATH. It usually takes a while to install all dependencies,
but should work fine once done.
To run rivet analysis, set 
```
doRivet = True
```
in runmodel.py file. Analysis currently does per-event analysis, lepton isolation, tau jet rejection and outputs a few observables (more to be added).

# UFO -> .hepmc -> plots!
