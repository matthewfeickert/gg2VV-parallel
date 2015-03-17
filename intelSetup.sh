#!/bin/bash

HOST=$(hostname)
if [ "${HOST:0:6}" == "lxplus" ] || [ "${HOST:0:7}" == "mflogin" ]; then
   if [ -f /afs/cern.ch/sw/IntelSoftware/linux/all-setup.sh ]; then
     source /afs/cern.ch/sw/IntelSoftware/linux/all-setup.sh intel64
   fi
fi
