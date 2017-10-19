#!/bin/bash

GREEN='\033[0;32m'
ENDC='\033[0m'

printf "${GREEN}..Checking OS...${ENDC}\n"
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
	platform='linux'
	printf "it's linux!\n"
elif [[ "$unamestr" == 'Darwin' ]]; then
	platform='mac'
	printf "it's Darwin!\n"
fi

if [ "$platform" == 'linux' ]; then
	BASHSOURCEFILE="bashrc"
elif [ "$platform" == 'mac' ]; then
	BASHSOURCEFILE="bash_profile"
fi


# download relevant packages if not found in current working directory
# add to path if found the packages
if [ -x "$(command -v mg5)" ]; then
	if ! [ -d "${PWD}/MG5_aMC_v2_6_0" ]; then
		printf "${GREEN}..Downloading MadGraph2.6.0...${ENDC}}\n"
		wget http://launchpad.net/madgraph5/2.0/2.6.x/+download/MG5_aMC_v2.6.0.tar.gz
		tar -xvf MG5_aMC_v2.6.0.tar.gz
		rm MG5_aMC_v2.6.0.tar.gz
	fi
	export PATH="$PATH:${PWD}/MG5_aMC_v2_6_0/bin"
fi

if [ -x "$(command -v rivet)" ]; then
	if ! [ -d "${PWD}/Rivet-2.5.4" ]; then
		printf "${GREEN}..Downloading Rivet-2.5.4...${ENDC}}\n"
		wget http://www.hepforge.org/archive/rivet/Rivet-2.5.4.tar.gz
		tar -xvf Rivet-2.5.4.tar.gz
		rm Rivet-2.5.4.tar.gz
	fi
	export PATH="$PATH:${PWD}/Rivet-2.5.4/bin"
fi

# This should detect bash abd zsh, which have a hash command that must
# be called to get it to forget past commands. Without forgetting 
# past commands the $PATH changes we made may not be respected
if [ -n "${BASH-}" -o -n "${ZSH_VERSION-}" ] ; then
	hash -r 2>/dev/null
fi
