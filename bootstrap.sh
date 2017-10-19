#!/bin/bash

GREEN='\033[0;32m'
WARN='\033[0;33m'
ENDC='\033[0m'

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
		printf "${GREEN}..Downloading MadGraph2.6.0...${ENDC}\n"
		wget http://launchpad.net/madgraph5/2.0/2.6.x/+download/MG5_aMC_v2.6.0.tar.gz > /dev/null 2>&1
		tar -xf MG5_aMC_v2.6.0.tar.gz
		rm MG5_aMC_v2.6.0.tar.gz
	fi
	export PATH="$PATH:${PWD}/MG5_aMC_v2_6_0/bin"
	printf "${GREEN}..Added MadGraph to PATH...${ENDC}\n"
	work_env_activated=false
else
	printf "${GREEN}..MadGraph detected...${ENDC}\n"
	
fi

if ! [ -x "$(command -v rivet)" ]; then
	printf "${WARN}..Rivet not detected!..${ENDC}\n"
	if ! [ -d "${PWD}/Rivet-2.5.4" ]; then
		printf "${GREEN}..Downloading Rivet-2.5.4...${ENDC}\n"
		wget http://www.hepforge.org/archive/rivet/Rivet-2.5.4.tar.gz > /dev/null 2>&1
		tar -xf Rivet-2.5.4.tar.gz
		rm Rivet-2.5.4.tar.gz
	fi
	export PATH="$PATH:${PWD}/Rivet-2.5.4/bin"
	printf "${GREEN}..Added Rivet to PATH...${ENDC}\n"
	work_env_activated=false
else
	printf "${GREEN}..Rivet detected...${ENDC}\n"
fi

if [ "$work_env_activated" = false ]; then
	PS1="(X)$PS1"
	export PS1
	work_env_activated=true
fi

# This should detect bash abd zsh, which have a hash command that must
# be called to get it to forget past commands. Without forgetting 
# past commands the $PATH changes we made may not be respected
if [ -n "${BASH-}" -o -n "${ZSH_VERSION-}" ] ; then
	hash -r 2>/dev/null
fi


