#!/bin/bash
# The idea of this script is to be able to download and install
# the latest version of gg2VV in a new directory just be executing
# this script. So making installation "turnkey"/"plug and play".
# Author: Matthew Feickert <mfeickert@smu.edu>
# Date: 2015-03-11

# Download the latest version of gg2VV
wget http://sourceforge.net/projects/hepsource/files/gg2VV/gg2VV-3.1.7.tar.bz2
# Extract it in the current directory
tar -xvf gg2VV-3.1.7.tar.bz2
# Copy the build clean script into the gg2VV version directory
cp clean_build.sh gg2VV-3.1.7
# Run the clean build
export TOPDIR=$PWD
export BUILDDIR=$HOME
cd gg2VV-3.1.7
./clean_build.sh "$TOPDIR" "$BUILDDIR"
