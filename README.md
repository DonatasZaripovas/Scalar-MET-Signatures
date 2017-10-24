# Scalar-MET-Signatures

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
NOTE: This should be run everytime after exiting the shell. It sets up the relevant paths to mg5/rivet/pythia.
If workspace is enabled successfully, you should see an (X) mark next to your shell prompt marker, i.e. 
```
(X)donatas@hopper:~/test_package/Scalar-MET-Signatures$
```
# Bootstrap explanation
This should detect if you have a MadGraph software installed and prompt you to install it if you do not have it.
Currently tested on MacOS and Linux distributions. If MadGraph is detected, paths are set for the $MG5Path/models/ directory
for implementing new models. The Example model (inside Example_UFO) is copied to this directory so that mg5 can access it.

The example UFO contains the operator:

![equation](http://latex.codecogs.com/gif.latex?%5Cmathcal%7BL%7D_n%3D%5Cleft%28%5Cfrac%7B%5Cphi%7D%7BM%7D%5Cright%29%5EnT%5E%7B%5Cnu%7D_%7B%5Cnu%7D%7E%7Ewith%7E%7En%3D1)

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

# Running the tool-chain
*OPTIONAL*
Once setup, simply running 
```
python runmodel.py
```
should go through the steps of adding the model to MG5, showering and doing per-event analysis in rivet.
*Otherwise can perform analysis manually*
```
cd run_mg5/
mg5
import model L10_1_kin_mass_SM # or other
generate p p > t t~, (t > b w+, w+ > j j), (t~ > b~ w-, w- > l- vl~)
output <model_output_filename>
launch <model_output_filename>
shower=Pythia8
0
set ickkw 1
set maxjetflavor 5 # perhaps doesn't matter, but I think easier for b-tagging?
set ktdurham 1 # matching algo
set use_syst False
/path/to/pythia8_card.dat # for stable b's
0
```
and waitt...

# UFO -> .hepmc -> plots!
