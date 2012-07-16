#!/bin/bash
# This script downloads, compiles, and installs our patched MAME, Rcade, and HiToText
# This only works for Debian-based systems, and possibly just for Debian Squeeze

# Make sure we are root
who=`whoami`
if [[ $who != 'root' ]]
then
    echo "You must run this script as root."
    exit 1
fi

# Confirm
echo -en "NOTE: This script has only been tested on Debian Squeeze, but should work\n(or can be made to work) on any Debian-based distribution. It will remove\nany current installation of MAME (sdlmame), Rcade, Wah!Cade, and HiToText.\nAn internet connection is required.\nContinue? ( y / N ) "
read yn
case $yn in
	[Yy]* );;
	* ) exit 0;;
esac

# Remove MAME, Rcade, and Wah!Cade if already installed
echo -en "**********\nChecking for previous installations...\n**********\n"
uninstalled=0
if [ -f /usr/local/bin/HiToText.exe ]
then
	echo "Removing HiToText..."
	rm -f /usr/local/bin/HiToText.exe
	rm -f /etc/sdlmame/HiToText.xml
fi
for p in "sdlmame" "rcade" "wahcade"
do
	dpkg -L $p  > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		/usr/bin/apt-get -y --force-yes --purge remove $p
		uninstalled=1
	fi
done
if [ $uninstalled -ne 0 ]
then
	echo -en "**********\nFor the cleanest possible Rcade installation, you may need to delete the .mame\nand .wahcade directories in your home folder.\n**********\n"
	sleep 1
fi

# Check if running Debian Squeeze
/usr/bin/apt-get -y install shtool
shtool platform -v -F "%sp" | grep "Debian GNU/Linux 6"  > /dev/null
if [[ $? -eq 0 ]]
then
	echo -en "**********\nChecking if backports is enabled...\n**********\n"
    # Make sure backports is in the sources.list (python-requests)
    grep "squeeze-backports" /etc/apt/sources.list > /dev/null
    if [[ $? -ne 0 ]]
    then
        echo "Enabling backports to install python-requests package (required for Debian Squeeze)"
        echo "" >> /etc/apt/sources.list
        echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> /etc/apt/sources.list
	else
		echo "Backports already enabled"
    fi
fi

# Update
/usr/bin/apt-get update

echo -en "**********\nInstalling dependencies...\n**********\n"
p=""
for t in `cat packages`
do
    p=`echo ${p} ${t}`
done
echo $p

# Install dependencies
/usr/bin/apt-get -y install $p

if [[ $? -eq 1 ]]
then
    print "Error:::"
    exit 1
fi

TIME=`date +%s`
BASE="/tmp/RcadeWithMAME-${TIME}"
mkdir -p $BASE
cd $BASE

# Download MAME, Rcade, and HiToText
echo -en "**********\nDownloading MAME...\n**********\n"
git clone git://github.com/johkelly/MAME_hi.git
echo -en "**********\nDownloading Rcade...\n**********\n"
git clone git://github.com/thevoiceless/wc-testing.git
echo -en "**********\nDownloading HiToText...\n**********\n"
git clone git://github.com/johkelly/HiToText_Mono.git

# Build MAME
echo -en "**********\nBuilding MAME...\n**********\n"
cd MAME_hi/mame-0.141
dpkg-buildpackage -uc -b
if [ "$?" -ne 0 ]
then
	echo "Error building MAME"
	exit 1
fi

# Build Rcade
echo -en "**********\nBuilding Rcade...\n**********\n"
cd $BASE
cd wc-testing/wahcade
./build_deb_package

# Build HiToText
echo -en "**********\nBuilding HiToText...\n**********\n"
cd $BASE
cd HiToText_Mono
make

# Install MAME
echo -en "**********\nInstalling MAME...\n**********\n"
cd $BASE
cd MAME_hi
dpkg -i sdlmame_0.141*.deb

# Ensure that mame does not update, as that will overwrite the high score patch
echo "sdlmame hold" | dpkg --set-selections

# Install Rcade
echo -en "**********\nInstalling Rcade...\n**********\n"
cd $BASE
cd wc-testing/wahcade/dist
dpkg -i rcade_*.deb

# "Install" HiToText
echo -en "**********\nInstalling HiToText...\n**********\n"
cd $BASE
cd HiToText_Mono
make install

# Remove files from /tmp
echo -en "**********\nCleaning up...\n**********\n"
cd /tmp
rm -rf $BASE
echo "Done."

echo ""
echo "----------"
echo "Next steps:"
echo "* Configure MAME in /etc/sdlmame/mame.ini"
echo "* Run Rcade once to create the ~/.wahcade folder if it does not already exist"
echo "* Configure Rcade via rcade-setup"
echo "----------"
echo ""