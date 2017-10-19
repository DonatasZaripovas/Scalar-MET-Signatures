#!/usr/bin/python

import os

os.system("source /home/donatas/ppt_local/bin/activate")

WARN  = '\033[93m'
GREEN = '\033[92m'
ENDC  = '\033[0m'

# Usage:   [ doIf, "top-decay"   , "shower" ]
# Options:
#					top-decay: "Hadronic", "Semileptonic", "Leptonic", "".
#					shower	 : "Pythia8" , "OFF".
doMG5    = [ True, "Semileptonic", "Pythia8" ]
doRivet  = False

# Change as appropriate
MG5Path   = os.getcwd()+"/run_mg5"
rivetPath = os.getcwd()+"/run_rivet"
if not os.path.exists(MG5Path):
    os.makedirs(MG5Path)

Models = ["L10_1_kin_mass_SM", "L10_3_kin_mass_SM", "L10_4_kin_mass_SM", "L10_2_kin_mass_SM"]
Models = ["L10_1_kin_mass_SM"]

if doMG5[0]:
	print GREEN+" ..Running MadGraph ..."+ENDC
	
	os.chdir(MG5Path)
	MG5Script = open('mg5runscript.mg5', 'w')

	# Set parameters from above

	_hadronic			= ", (t > b w+, w+ > j j), (t~ > b~ w-, w- > j j)"
	_semileptonic = ", (t > b w+, w+ > j j), (t~ > b~ w-, w- > l- vl~)"
	_leptonic			= ", (t > b w+, w+ > l+ vl), (t~ > b~ w-, w- > l- vl~)"
	_default			= ""
	_finalState = (_hadronic     if doMG5[1]=="Hadronic"     else \
								(_semileptonic if doMG5[1]=="Semileptonic" else \
								(_leptonic     if doMG5[1]=="Leptonic"     else \
								 _default)))
	if _finalState == _default:
		print WARN + "WARNING: UNKNOWN FINAL STATE, USING NO DECAY OF TOPS" + ENDC
	
	_shower			  = doMG5[2]

  
	# Begin model run #########################
	for model in Models:
		if "L10" in model:
			_process = "x0"
		elif ("L1" in model) or ("L2" in model):
			_process = "x0 x0"

		MG5Script.write("import model " + model    + '\n' \
										"generate p p > t t~ "    + _process + " " + _finalState + '\n' \
										"output PROC_" + model    + '\n' \
									  "launch PROC_" + model    + '\n' \
										"shower = "    + _shower  + '\n' \
										"0\n" \
										"set use_syst False\n" \
										+MG5Path+"/Pythia8_cards/pythia8_card.dat\n" \
										"0\n")
		MG5Script.close()
		os.system(MG5Path+"/bin/mg5 mg5runscript.mg5")
		os.chdir(MG5Path + "/PROC_" + model + "/Events/run_01")
		print GREEN+"..Extracting Pythia output..."+ENDC
		os.system("gunzip -k tag_1_pythia8_events.hepmc.gz")

if doRivet:
	print GREEN+"..Running Rivet Analysis..."+ENDC
	os.chdir(rivetPath)
	os.system('export RIVET_ANALYSIS_PATH=rivetPath')
	for model in Models:
		os.system(rivetPath+"/bin/rivet --analysis=Missing_momentum "+MG5Path+"/PROC_"+model+"/Events/run_01/tag_1_pythia8_events.hepmc -o PROC_"+model+".yoda")

