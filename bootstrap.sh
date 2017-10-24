#!/bin/bash

GREEN='\033[0;32m'
WARN='\033[0;33m'
ENDC='\033[0m'

work_env_activated=false

printf "${GREEN}..Checking OS...${ENDC}\n"
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
	platform='linux'
	printf "${GREEN}Detected Linux!${ENDC}\n"
elif [[ "$unamestr" == 'Darwin' ]]; then
	platform='mac'
	printf "${GREEN}Detected Darwin!${ENDC}\n"
fi

if [ "$platform" == 'linux' ]; then
	BASHSOURCEFILE="bashrc"
elif [ "$platform" == 'mac' ]; then
	BASHSOURCEFILE="bash_profile"
fi


# download relevant packages if not found in current working directory
# add to path if found the packages
if ! [ -x "$(command -v mg5)" ]; then
	
	printf "${WARN}..MadGraph not detected!..${ENDC}\n"
	if ! [ -d "${PWD}/MG5_aMC_v2_6_0" ]; then
		printf "${WARN}..Would you like to install MadGraph2.6.0? ${ENDC}\n"
		read -p "..(y/n)?..." -n 1 -r
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			printf "${GREEN}..Downloading MadGraph2.6.0...${ENDC}\n"
			curl --http1.1 http://launchpad.net/madgraph5/2.0/2.6.x/+download/MG5_aMC_v2.6.0.tar.gz --output MG5_aMC_v2.6.0.tar.gz
			# wget http://launchpad.net/madgraph5/2.0/2.6.x/+download/MG5_aMC_v2.6.0.tar.gz > /dev/null 2>&1
			curl -LO http://launchpad.net/madgraph5/2.0/2.6.x/+download/MG5_aMC_v2.6.0.tar.gz
			tar -xf MG5_aMC_v2.6.0.tar.gz
			rm MG5_aMC_v2.6.0.tar.gz
			export PATH="$PATH:${PWD}/MG5_aMC_v2_6_0/bin"
			printf "${GREEN}..Added MadGraph to PATH...${ENDC}\n"
			MG5ExePath=`which mg5`
			work_env_activated=true
		else
			printf "${WARN}..Skipping installation of MadGraph! Please resolve this yourself or rerun the bootstrap for automatic installation.${ENDC}\n"
			work_env_activated=false
		fi
	else	
		export PATH="$PATH:${PWD}/MG5_aMC_v2_6_0/bin"
		printf "${GREEN}..Added MadGraph to PATH...${ENDC}\n"
		MG5ExePath=`which mg5`
		work_env_activated=true
	fi
else
	printf "${GREEN}..MadGraph detected in...${ENDC}\n"
	MG5ExePath=`which mg5`
	echo $MG5ExePath
fi

# If example_ufo is not in the model directory of MG5, put it there.
if [ ! -d "${MG5ExePath%bin*}"/models/L10_1_kin_mass_SM ]; then
	printf "${GREEN}..Copying Example_UFO to MadGraph model folder...${ENDC}\n"
	cp -r Example_UFO/L10_1_kin_mass_SM "${MG5ExePath%bin*}"/models/
fi

if ! [ -x "$(command -v rivet)" ]; then
	printf "${WARN}..Rivet not detected!..${ENDC}\n"
	if [ -f $PWD/local/bin/rivet ]; then
		printf "${GREEN}..Phew..Found it !..${ENDC}\n"
		source "$PWD/local/rivetenv.sh"
		printf "${GREEN}..Added Rivet to PATH...${ENDC}\n"
		work_env_activated=true
	else
		printf "${WARN}..Would you like to install Rivet? The installation might take a while and will install GSL, HEPMC, FASTJET, YODA and RIVET if not found locally. \n All packages will by default be installed in $PWD/local/ . Type '"'n'"' if you would rather do it yourself. ${ENDC}\n"
		read -p "..(y/n)?..." -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			printf "${GREEN}..Continuing with Rivet installation..This may take a while!..${ENDC}\n"
			if ! [ -f $PWD/rivet-bootstrap ]; then
				wget http://rivet.hepforge.org/hg/bootstrap/raw-file/2.5.4/rivet-bootstrap
			fi
			
			export YODA_CONFFLAGS=--enable-root=no
			source rivet-bootstrap
			source "$PWD/local/rivetenv.sh"
			printf "${GREEN}..Added Rivet to PATH...${ENDC}\n"
		else
			printf "${WARN}..Skipping installation of Rivet! Please resolve this yourself or rerun the bootstrap for automatic installation.${ENDC}\n"
			work_env_activated=false
		fi
	fi
else
	printf "${GREEN}..Rivet detected in...${ENDC}\n"
	RivetExePath=`which rivet`
	echo $RivetExePath
fi

if [ -d $PWD/run_rivet ]; then
	export RIVET_ANALYSIS_PATH=$PWD/run_rivet
fi

# If pythia8 not integrated with MG5 then download and install interface
if [ ! -d "${MG5ExePath%bin*}"/HEPTools/pythia8/ ]; then
	printf "${WARN}..Pythia8 interface with MG5 not detected, please let me install...Continue?${ENDC}\n"
	read -p "..(y/n)?..." -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		printf "${GREEN}..Continuing with pythia8 integration, this may take a while!..${ENDC}\n"
		echo "install pythia8" > $PWD/run_mg5/pythia_install.mg5
		cd $PWD/run_mg5
		mg5 pythia_install.mg5
		cd -
	else
		printf "${WARN}..Skipping installation of Pythia8! Please resolve this yourself or rerun the bootstrap for automatic installation.${ENDC}\n"
		work_env_activated=false
	fi
fi

if [ "$work_env_activated" = true ]; then
	PS1="(X)$PS1"
	export PS1
	work_env_activated=false
fi

# This should detect bash abd zsh, which have a hash command that must
# be called to get it to forget past commands. Without forgetting 
# past commands the $PATH changes we made may not be respected
if [ -n "${BASH-}" -o -n "${ZSH_VERSION-}" ] ; then
	hash -r 2>/dev/null
fi
