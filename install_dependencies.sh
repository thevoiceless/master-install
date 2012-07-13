#!/bin/bash

# Make sure we are root
who=`whoami`
if [[ $who != 'root' ]]
then
    echo "Must be root"
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
        echo "Enabling backports to install python-requests package"
        echo "" >> /etc/apt/sources.list
        echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> /etc/apt/sources.list
    fi
fi

# Update
/usr/bin/apt-get update

p=""
for t in `cat packages`
do
    p=`echo ${p} ${t}`
done
echo $p

# Install all needed packages
/usr/bin/apt-get -y install $p

if [[ $? -eq 1 ]]
then
    print "Error:::"
    exit 1
fi