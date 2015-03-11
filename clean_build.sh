#!/bin/bash

# ORIGINAL
# Author: Doug Schouten <doug.schouten@triumf.ca>
# Date: 2012-11-09

#
# builds mixed QUAD and DBLE precision with Intel compilers
#
# NOTE create Jamrules.INTEL_BOTH  Jamrules.INTEL_DBLE  Jamrules.INTEL_QUAD in a build-rules/ folder
# in which the PRECISION is set to MIXED, DOUBLE, and QUAD, respectively (all other configurations the same)
#
# see L160+ for how these are used
#

# EDITED
# Author: Matthew Feickert <mfeickert@smu.edu>
# Date: 2013-03-11

if [ "$1" == "verbose" ]; then  # If verbose option then output to stdout
  set -v
fi

################################################ options #####################################################

# If the build directory doesn't exist, then make it
if [ ! -d "gg2VV-new" ]; then
  mkdir ./gg2VV-new
fi

# HOME install
#export PACKDIR=$HOME/gg2VV-new ## where to build & run
# Local install
export PACKDIR=$PWD/gg2VV-new ## where to build & run

#export DOWNLOAD=0 ## set to one to download fresh sources
export DOWNLOAD=1 ## set to one to download fresh sources       # Set for CLEAN INSTALL
#export BUILD=0 ## set to one to (re)build all packages
export BUILD=1 ## set to one to (re)build all packages       # Set for CLEAN INSTALL
export REFRESH=1 ## set to one to unpack + build the gg->VV source (*not* the external packages)

GG2VV_VERSION="3.1.7"
LOOP_TOOLS_VERSION="2.8_20120918" ## check correct version number from http://gg2vv.hepforge.org/
LOOP_TOOLS_BASE_VERSION="2.8"

## probably no need to change these ...
OMNI_VERSION="4.1.6" 
LHAPDF_VERSION="5.8.8"
JAM_VERSION="2.5"

##############################################################################################################

## for LXPLUS ## 

HOST=$( hostname )
if [ "${HOST:0:6}" == "lxplus" ]; then
    if [ -f /afs/cern.ch/sw/IntelSoftware/linux/all-setup.sh ]; then
	source /afs/cern.ch/sw/IntelSoftware/linux/all-setup.sh intel64
    fi
fi
unset HOST

if [ ${BUILD} -eq 1 ]; then

    if [ ${DOWNLOAD} -eq 1 ]; then

        # Download and prepare
        # --------------------
	
        cd $PACKDIR

	rm -rf omniORB-${OMNI_VERSION}.tar.bz2
	wget http://downloads.sourceforge.net/project/omniorb/omniORB/omniORB-${OMNI_VERSION}/omniORB-${OMNI_VERSION}.tar.bz2

	rm -rf lhapdf-${LHAPDF_VERSION}.tar.gz
	wget http://www.hepforge.org/archive/lhapdf/lhapdf-${LHAPDF_VERSION}.tar.gz

	rm -rf jam-${JAM_VERSION}.tar
	wget ftp://ftp.perforce.com/jam/jam-${JAM_VERSION}.tar


	rm -rf gg2VV-${GG2VV_VERSION}.tar.bz2
	URL="http://downloads.sourceforge.net/project/hepsource/gg2VV"
	wget "${URL}/gg2VV-${GG2VV_VERSION}.tar.bz2?r=http://gg2vv.hepforge.org/&use_mirror=switch" \
	    -O gg2VV-${GG2VV_VERSION}.tar.bz2

	rm -rf LoopTools-${LOOP_TOOLS_VERSION}.tar.gz 
	wget http://gg2vv.hepforge.org/LoopTools-${LOOP_TOOLS_VERSION}.tar.gz 
	
	rm -rf lhapdf-${LHAPDF_VERSION}/ && tar xzf lhapdf-${LHAPDF_VERSION}.tar.gz
	rm -rf LoopTools-*/ && tar xzf LoopTools-${LOOP_TOOLS_VERSION}.tar.gz
	rm -rf omniORB-${OMNI_VERSION}/ && tar xjf omniORB-${OMNI_VERSION}.tar.bz2
	rm -rf jam-${JAM_VERSION}/ && tar xf jam-${JAM_VERSION}.tar
	
	mkdir -p libraries/lhapdf-pdfsets
	mkdir -p libraries/intel
	
	pushd libraries/intel
	
	mkdir -p lhapdf-${LHAPDF_VERSION}
	mkdir -p LoopTools-${LOOP_TOOLS_BASE_VERSION}
	mkdir -p omniORB-${OMNI_VERSION}
	
	[ ! -f lhapdf ] && ln -s lhapdf-${LHAPDF_VERSION}  lhapdf
	[ ! -f LoopTools ] && ln -s LoopTools-${LOOP_TOOLS_BASE_VERSION} LoopTools
	[ ! -f omniORB ] && ln -s omniORB-${OMNI_VERSION} omniORB
	
	cd LoopTools && ln -s lib64 lib && cd -

	popd
    fi
    
# Jam
# ---

    pushd $PACKDIR/jam-${JAM_VERSION}
    make
    cp -r bin.linux/ $PACKDIR/libraries/intel/jam
    popd
 
# LoopTools
# ---------

    pushd $PACKDIR/LoopTools-${LOOP_TOOLS_BASE_VERSION}/
    export FC="ifort"
    ./configure --prefix=$PACKDIR/libraries/intel/LoopTools-${LOOP_TOOLS_BASE_VERSION}
    make -j4
    make install
    make clean
    make -f makefile.quad-ifort
    make -f makefile.quad-ifort install
    make -f makefile.quad-ifort clean 
    ln -s lib64 lib
    popd

# LHAPDF
# ------

    export GFORTRAN="ifort"
    pushd $PACKDIR/lhapdf-${LHAPDF_VERSION}/
   ./configure --prefix=$PACKDIR/libraries/intel/lhapdf-${LHAPDF_VERSION}
   make -j4 
   make install
   popd

# omniORB
# -------

    export CC="icc" 
    export CXX="icpc"
    mkdir -p $PACKDIR/config
    mkdir -p $PACKDIR/system/log
     
     pushd $PACKDIR/omniORB-${OMNI_VERSION}

     mkdir build
     pushd build

     ../configure --prefix=$PACKDIR/libraries/intel/omniORB-${OMNI_VERSION} \
 	--with-omniORB-config=$PACKDIR/config/omniORB.cfg \
 	--with-omniNames-logdir=$PACKDIR/system/log/omninames
     make -j4
     make install
     popd
     popd

fi

# gg2VV
# -----

pushd $PACKDIR

export LOOPTOOLS_TOPDIR=$PACKDIR/libraries/intel/LoopTools/
export LHAPDF_TOPDIR=$PACKDIR/libraries/intel/lhapdf/
export OMNIORB_TOPDIR=$PACKDIR/libraries/intel/omniORB/

export PATH=$PATH:$OMNIORB_TOPDIR/bin
export PATH=$PATH:$PACKDIR/libraries/intel/jam

export TOPDIR=$PWD/gg2VV-${GG2VV_VERSION}

if [ $REFRESH -eq 1 ]; then
    rm -rf $TOPDIR
    tar xjf gg2VV-${GG2VV_VERSION}.tar.bz2
fi

rm -rf jam.log
touch  jam.log

pushd $TOPDIR 

# prescription from amplitude/README.mixed_precision
# --------------------------------------------------

## cp ../patches/events.cpp gg2VV/events.cpp ## patch for LHAGLUE error 

pushd amplitude; python generate_quadruple_code.py; popd

[ ! -f Jamrules.bak ] && cp Jamrules Jamrules.bak

cp ../build-rules/Jamrules.INTEL_DBLE Jamrules
pushd gg2VV; jam gg2VV ; jam gg2VV ; popd

cp ../build-rules/Jamrules.INTEL_QUAD Jamrules
pushd gg2VV; jam gg2VV ; jam gg2VV ; popd

pushd amplitude; echo "$PACKDIR/libraries/intel/LoopTools/lib64" \
    | python generate_quadruple_suffix_libraries.py; popd

cp ../build-rules/Jamrules.INTEL_BOTH Jamrules
pushd gg2VV; jam gg2VV ; jam gg2VV ; popd

popd ## << back in PACKDIR

rm -rf gg2VV.bin

[ ! -L gg2VV.bin ] && ln -s gg2VV-${GG2VV_VERSION}/gg2VV/gg2VV gg2VV.bin

