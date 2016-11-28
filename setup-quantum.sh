#!/bin/bash
set -x;  # verbose
set -e;  # exit on error

BOOSTVER=1.62.0;
QUANTUM=/Applications/Quantum.app
INCLUDEDIR=${QUANTUM}/Contents/Resources/.kivy/include;
LIBDIR=${QUANTUM}/Contents/Resources/.kivy/lib;
KIVYDIR=${QUANTUM}/Contents/Resources/.kivy;


if [ -d /Applications/Quantum.app ] ; then
    rm -rf /Applications/Quantum.app;
fi
cp -a Kivy.app ${QUANTUM}
cp -a /usr/local/llvm/lib/libomp.dylib ${LIBDIR}/libomp.dylib;
#install_name_tool -id @executable_path/.kivy/lib/libomp.dylib ${LIBDIR}/libomp.dylib;
pushd ${QUANTUM};
pip install git+http://github.com/tito/osxrelocator;
osxrelocator -r . @rpath/libomp.dylib @executable_path/.kivy/mods/libomp.dylib;
popd;

if [ -f /usr/local/bin/kivy ] ; then
    rm -rf /usr/local/bin/kivy;
fi
ln -s ${QUANTUM}/Contents/Resources/script /usr/local/bin/kivy;

# -- Install remaining requirements
kivy -m pip install -r data/requirements.txt;
if [ ! -d cache ] ; then
    mkdir cache;
fi;
pushd cache;
if [ -d mogwai ] ; then
    rm -rf mogwai;
fi
git clone git@github.com:uclatommy/mogwai.git;
pushd mogwai;
kivy -m setup install;
popd; #mogwai

# -- Install portable HDF5 and tables
# Note: tables comes with a suite of tests you can use to test the installation:
# >>> import tables
# >>> tables.test()
cp -a /usr/local/Cellar/hdf5/*/lib/libhdf5.10.dylib ${LIBDIR}
cp -a /usr/local/Cellar/hdf5/*/include/* ${INCLUDEDIR}/
#install_name_tool -id @executable_path/.kivy/lib/libhdf5.10.dylib ${LIBDIR}/libhdf5.10.dylib
pushd ${QUANTUM}
osxrelocator . ${LIBDIR}/ @executable_path/.kivy/lib/
popd;
kivy -m pip install --install-option='--hdf5=$KIVYDIR' tables

# -- Install Quantum module
# Build the Quantum python extension and copy all necessary headers for building plugins
if [ ! -d Quantum ]; then
    git clone git@github.com:uclatommy/Quantum.git;
fi;
if [ ! -d ${INCLUDEDIR}/Engine ]; then
    mkdir ${INCLUDEDIR}/Engine;
fi;
cp -a Quantum/QuantumCPP/Engine/*.h* ${INCLUDEDIR}/Engine;
cp -a Quantum/QuantumCell/Engine/*.h* ${INCLUDEDIR}/Engine;

pushd Quantum/QuantumCell;
if [ -d build ]; then
    rm -rf build;
fi;
mkdir build && cd build;
cmake ..;
make install;
popd; # Quantum/QuantumCell
pushd Quantum/QuantumAPI/src;
python3 setup-llvm7.py build_ext --inplace -f;
popd; # Quantum/QuantumAPI/src
pushd ${QUANTUM};
osxrelocator -r . ./Contents/Frameworks/python/3.5.2/lib/ @executable_path/../Frameworks/python/3.5.2/lib/;
popd; # ${QUANTUM}

# -- Install plugins
if [! -d Quantum-PyCell ]; then
    git clone git@github.com:uclatommy/Quantum-PyCell.git;
fi;
pushd Quantum-PyCell;
if [ -d build ]; then
    rm -rf build;
fi;
mkdir build && cd build;
cmake ..;
make install;
popd;

# -- Install source code
mkdir ${QUANTUM}/Contents/Resources/yourapp
cp -a Quantum/QuantumGUI/src/* ${QUANTUM}/Contents/Resources/yourapp

popd; #cache
echo "Done!";
