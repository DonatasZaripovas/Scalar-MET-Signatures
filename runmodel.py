#!/usr/bin/python

import os

WARN  = '\033[93m'
GREEN = '\033[92m'
ENDC  = '\033[0m'

# Usage:   [ doIf, "top-decay"   , "shower" ]
####################################################### Options:
#top-decay: "Hadronic", "Semileptonic", "Leptonic", "".
#shower	 : "Pythia8" , "OFF".
doMG5    = [ True, "Semileptonic", "Pythia8" ]
doMatching = True
doRivet  = True

# The included example model
#Models = ["L10_1_kin_mass_SM"]
Models = ["sm-full", "L10_1_kin_mass_SM"]

# can produce extra scalars if model allows, i.e. for L10_4 make extraScalars = "x0 x0 x0 x0"
# if not allowed leave blank, i.e. extraScalars = ""
extraScalars = ""

###################################### RUN CARDS AND RUNS #########################
# Change as appropriate
MG5Path   = os.getcwd()+"/run_mg5"
rivetPath = os.getcwd()+"/run_rivet"
#print MG5Path
#print rivetPath
if not os.path.exists(MG5Path):
    os.makedirs(MG5Path)

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

  
	# Write out run card for madgraph #########################
	for model in Models:
		outFileName = "PROC_" + model + doMG5[1]
		if doMatching:
			outFileName += "_Match"
		else:
			outFileName += "_noMatch"

		MG5Script.write(
										"import model " + model    + "\n" \
										"generate p p > t t~ "        + extraScalars + " " + _finalState + "@0\n" \
										)
		if doMatching:
			MG5Script.write(
										"add process p p > t t~ j "   + extraScalars + " " + _finalState + "@1\n" \
										"add process p p > t t~ j j " + extraScalars + " " + _finalState + "@2\n" \
										)
		MG5Script.write(
										"output " + outFileName    + "\n" \
									  "launch " + outFileName    + "\n" \
										"shower=" + _shower				+ "\n" \
										"0\n" \
										)
		# add parameters for jet matching if requested 
		if doMatching:
			MG5Script.write("set ickkw 1\n" \
										  "set maxjetflavor 5\n" \
											"set ktdurham 1\n" \
											)
		# pythia card and no systematics
		MG5Script.write(
										"set use_syst False\n" \
										+MG5Path+"/Pythia8_cards/pythia8_card.dat\n" \
										"0\n" \
										)
		MG5Script.close()
		os.system("mg5 mg5runscript.mg5")
		os.chdir(MG5Path + "/" + outFileName + "/Events/run_01")
		print GREEN+"..Extracting Pythia output..."+ENDC
		os.system("gunzip -k tag_1_pythia8_events.hepmc.gz")

if doRivet:
	print GREEN+"..Running Rivet Analysis..."+ENDC
	try:
		outFileName
	except NameError:
		outFileName = "PROC_" + model + doMG5[1]
		if doMatching:
			outFileName += "_match"

	os.chdir(rivetPath)
	os.system("rivet-buildplugin Rivet_Missing_momentum.so Missing_momentum.cc")
	for model in Models:
		extension = model
		os.system("rivet --analysis=Missing_momentum "+MG5Path+"/"+outFileName+"/Events/run_01/tag_1_pythia8_events.hepmc -o "+outFileName+".yoda")
	print "Now run rivet-mkhtml <file1.yoda>:'Name this file' <file2.yoda>:'Name the second file'  etc..."
