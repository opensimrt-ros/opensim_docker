#!/usr/bin/env bash

##ld library env needs to be sourced or python doesn't work. it shows the error >>> 111: ImportError: libSimTKmath.so.3.8: cannot open shared object file: No such file or directory

#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/opensim_install/lib/
apt install python3-setuptools --yes
make -j12 install
cd /root/opensim_install/lib/python3.6/site-packages/
python3 setup.py install

