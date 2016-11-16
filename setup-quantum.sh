#!/bin/bash
set -x  # verbose
set -e  # exit on error

BOOSTVER=1.62.0

if [ -d /Applications/Quantum.app ] ; then
    rm -rf /Applications/Quantum.app;
fi
cp -a Kivy.app /Applications/Quantum.app
cp -a /usr/local/llvm/lib/libomp.dylib /Applications/Quantum.app/Contents/Resources/.kivy/lib/libomp.dylib;
install_name_tool -id @executable_path/.kivy/lib/libomp.dylib /Applications/Quantum.app/Contents/Resources/.kivy/lib/libomp.dylib;

if [ -f /usr/local/bin/kivy ] ; then
    rm -rf /usr/local/bin/kivy;
fi
ln -s /Applications/Quantum.app/Contents/Resources/script /usr/local/bin/kivy;

# -- Install remaining requirements
kivy -m pip install -r data/requirements.txt;
if [ ! -d cache ] ; then
    mkdir cache;
fi;
pushd cache;
if [ -d mogwai ] ; then
    rm -rf mogwai;
fi
git clone https://github.com/uclatommy/mogwai.git;
pushd mogwai;
kivy -m setup install;
popd; #mogwai

# -- Install portable HDF5 and tables
# Note: tables comes with a suite of tests you can use to test the installation:
# >>> import tables
# >>> tables.test()
cp -a /usr/local/Cellar/hdf5/*/lib/libhdf5.10.dylib /Applications/Quantum.app/contents/resources/.kivy/lib
cp -a /usr/local/Cellar/hdf5/*/include/* /Applications/Quantum.app/contents/resources/.kivy/include/
install_name_tool -id @executable_path/.kivy/lib/libhdf5.10.dylib /Applications/Quantum.app/contents/resources/.kivy/lib/libhdf5.10.dylib
kivy -m pip install --install-option='--hdf5=/Applications/Quantum.app/contents/resources/.kivy' tables

# -- Install Quantum module
# Build the Quantum python extension and copy all necessary headers for building plugins
git clone https://github.com/uclatommy/quantum.git


# -- Install plugins

popd; #cache
echo "Done!";
