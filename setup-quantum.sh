#!/bin/bash
set -x;  # verbose
set -e;  # exit on error

SCRIPT_PATH="${BASH_SOURCE[0]}";
if([ -h "${SCRIPT_PATH}" ]) then
  while([ -h "${SCRIPT_PATH}" ]) do SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
fi
SCRIPT_PATH=$(python -c "import os; print(os.path.realpath(os.path.dirname('${SCRIPT_PATH}')))")

BOOSTVER=1.63.0;
PYTHONVER=3.6.1;
QUANTUM=/Applications/Quantum.app
INCLUDEDIR=${QUANTUM}/Contents/Resources/.kivy/include;
LIBDIR=${QUANTUM}/Contents/Resources/.kivy/lib;
KIVYDIR=${QUANTUM}/Contents/Resources/.kivy;


if [ -d /Applications/Quantum.app ] ; then
    rm -rf /Applications/Quantum.app;
fi
cp -a Kivy.app ${QUANTUM}
cp -a /usr/local/llvm/lib/libomp.dylib ${LIBDIR}/libomp.dylib;
install_name_tool -id @executable_path/../Resources/.kivy/lib/libomp.dylib ${LIBDIR}/libomp.dylib

if [ -f /usr/local/bin/quantum ] ; then
    rm -rf /usr/local/bin/quantum;
fi
ln -s ${QUANTUM}/Contents/Resources/script /usr/local/bin/quantum;

# -- Install remaining requirements
kivy -m pip install -r data/requirements.txt;
if [ ! -d cache ] ; then
    mkdir cache;
fi;
pushd cache;
if [ ! -d mogwai ] ; then
    git clone git@github.com:uclatommy/mogwai.git;
fi;
pushd mogwai;
quantum -m setup install;
popd; #mogwai

# -- Install portable HDF5 and tables
# Note: tables comes with a suite of tests you can use to test the installation:
# >>> import tables
# >>> tables.test()
cp -a /usr/local/Cellar/hdf5/*/lib/libhdf5.10.dylib ${LIBDIR}
cp -R /usr/local/Cellar/hdf5/*/include/. ${INCLUDEDIR}/
install_name_tool -id @executable_path/../Resources/.kivy/lib/libhdf5.10.dylib ${LIBDIR}/libhdf5.10.dylib
install_name_tool -id @executable_path/../Resources/.kivy/lib/libiomp5.dylib ${LIBDIR}/libiomp5.dylib
pushd ${LIBDIR};
osxrelocator -r . ./Contents/Resources @executable_path/../Resources;
popd;
quantum -m pip install --install-option='--hdf5=$KIVYDIR' tables

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
CC=/usr/local/llvm/bin/clang CXX=/usr/local/llvm/bin/clang++ cmake ..;
make install;
popd; # Quantum/QuantumCell
pushd Quantum/QuantumAPI/src;
quantum setup.py build_ext --inplace -f;
popd; # Quantum/QuantumAPI/src

# -- Install plugins
if [ ! -d Quantum-PyCell ]; then
    git clone git@github.com:uclatommy/Quantum-PyCell.git;
fi;
pushd Quantum-PyCell;
if [ -d build ]; then
    rm -rf build;
fi;
mkdir build && cd build;
CC=/usr/local/llvm/bin/clang CXX=/usr/local/llvm/bin/clang++ cmake ..;
make install;
popd;

# -- Install source code
mkdir ${QUANTUM}/Contents/Resources/QuantumApp
cp -a Quantum/QuantumGUI/src/* ${QUANTUM}/Contents/Resources/QuantumApp

# -- Patch sphinx-build
# TODO: Maybe not necessary. Doc build is now configured to use the virtual env. Review for removal.
var="#!\/Applications\/Quantum.app\/Contents\/Resources\/python"
sed "1s/.*/$var/" /Applications/Quantum.app/Contents/Frameworks/python/3.6.1/bin/sphinx-build
sed "1s/.*/$var/" /Applications/Quantum.app/Contents/Frameworks/python/3.6.1/bin/sphinx-autogen
sed "1s/.*/$var/" /Applications/Quantum.app/Contents/Frameworks/python/3.6.1/bin/sphinx-apidoc
sed "1s/.*/$var/" /Applications/Quantum.app/Contents/Frameworks/python/3.6.1/bin/sphinx-quickstart

popd; #cache
osxrelocator -r ${KIVYDIR} ./libomp.dylib @executable_path/../Resources/.kivy/lib/libomp.dylib
cp data/quantum.ini ${QUANTUM}/Contents/Resources/QuantumApp

echo "Done!";
