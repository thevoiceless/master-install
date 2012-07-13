#!/bin/bash
# This script downloads, compiles, and installs our patched MAME, Rcade, and HiToText
# This only works for Debian-based systems, and possibly just for Debian Squeeze

# Make sure we are root
who=`whoami`
if [[ $who != 'root' ]]
then
    echo "You must be root"
    exit 1
fi

# Check if running Debian Squeeze
/usr/bin/apt-get -y install shtool
shtool platform -v -F "%sp" | grep "Debian GNU/Linux 6"  > /dev/null
if [[ $? -ne 0 ]]
then
    # Make sure backports is in the sources.list (python-requests)
    grep "squeeze-backports" /etc/apt/sources.list > /dev/null
    if [[ $? -eq 1 ]]
    then
        echo "Enabling backports to install python-requests package (required for Debian Squeeze)"
        echo "" >> /etc/apt/sources.list
        echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> /etc/apt/sources.list
    fi
fi

# Update
/usr/bin/apt-get update

echo "Installing dependencies"
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

USER=`whoami`
TIME=`date +%s`
BASE="/tmp/RcadeWithMAME-${TIME}"
mkdir -p $BASE
cd $BASE

# Download MAME, Rcade, and HiToText
echo "Downloading MAME..."
git clone git://github.com/johkelly/MAME_hi.git
echo "Downloading Rcade..."
git clone git://github.com/thevoiceless/wc-testing.git
echo "Downloading HiToText..."
git clone git://github.com/johkelly/HiToText_Mono.git

# Build MAME
echo "Building MAME..."
cd MAME_hi/mame-0.141
dpkg-buildpackage -uc -b
if [ "$?" -ne 0 ]
then
	echo "Error building MAME"
	exit 1
fi

# Build Rcade
echo "Building Rcade..."
cd $BASE
cd wc-testing/wahcade
./build_deb_package

# Build HiToText
echo "Building HiToText..."
cd $BASE
cd HiToText_Mono
make

# Install MAME
echo "Installing MAME..."
cd $BASE
cd MAME_hi
dpkg -i sdlmame_0.141*.deb

# Install Rcade
echo "Installing Rcade"
cd $BASE
cd wc-testing/wahcade/dist
dpkg -i rcade_*.deb

# "Install" HiToText
echo "Installing HiToText..."
cd $BASE
cd HiToText_Mono
make install

echo "Done."
