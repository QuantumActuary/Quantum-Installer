#!/bin/bash
set -x #verbose
set -e #exit on error

if [ ! -f aria2-1.19.3-osx-darwin.dmg ] ; then
    curl -O -L https://github.com/tatsuhiro-t/aria2/releases/download/release-1.19.3/aria2-1.19.3-osx-darwin.dmg;
fi
hdiutil attach aria2-1.19.3-osx-darwin.dmg;
sudo installer -package "/Volumes/aria2 1.19.3 Intel/aria2.pkg" -target /;
if [ ! -f SDL2-2.0.4.dmg ] ; then
    curl -O -L https://www.libsdl.org/release/SDL2-2.0.4.dmg;
fi
if [ ! -f SDL2_image-2.0.1.dmg ] ; then
    curl -O -L https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.1.dmg;
fi
if [ ! -f SDL2_mixer-2.0.1.dmg ] ; then
    curl -O -L https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.1.dmg;
fi
if [ ! -f SDL2_ttf-2.0.13.dmg ] ; then
    curl -O -L https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.13.dmg;
fi
if [ ! -f gstreamer-1.0-1.7.1-x86_64.pkg ] ; then
    /usr/local/aria2/bin/aria2c -x 10 http://gstreamer.freedesktop.org/data/pkg/osx/1.7.1/gstreamer-1.0-1.7.1-x86_64.pkg;
fi
if [ ! -f gstreamer-1.0-devel-1.7.1-x86_64.pkg ] ; then
    /usr/local/aria2/bin/aria2c -x 10 http://gstreamer.freedesktop.org/data/pkg/osx/1.7.1/gstreamer-1.0-devel-1.7.1-x86_64.pkg;
fi
if [ ! -f platypus.zip ] ; then
    curl -O -L http://www.sveinbjorn.org/files/software/platypus.zip;
fi
if [ ! -f Keka-1.0.4-intel.dmg ] ; then
    curl -O -L http://www.kekaosx.com/release/Keka-1.0.4-intel.dmg;
fi
hdiutil attach Keka-1.0.4-intel.dmg;
hdiutil attach SDL2-2.0.4.dmg;
sudo cp -a /Volumes/SDL2/SDL2.framework /Library/Frameworks/;
hdiutil attach SDL2_image-2.0.1.dmg;
sudo cp -a /Volumes/SDL2_image/SDL2_image.framework /Library/Frameworks/;
hdiutil attach SDL2_ttf-2.0.13.dmg;
sudo cp -a /Volumes/SDL2_ttf/SDL2_ttf.framework /Library/Frameworks/;
hdiutil attach SDL2_mixer-2.0.1.dmg;
sudo cp -a /Volumes/SDL2_mixer/SDL2_mixer.framework /Library/Frameworks/;
# Note: fails to overwrite existing installation which causes python3 compile error later.
sudo installer -package gstreamer-1.0-1.7.1-x86_64.pkg -target /;
sudo installer -package gstreamer-1.0-devel-1.7.1-x86_64.pkg -target /;
unzip platypus.zip;
mkdir -p /usr/local/bin;
mkdir -p /usr/local/share/platypus;
mkdir -p /usr/local/man/platypus;
cp Platypus-5.1/Platypus.app/Contents/Resources/platypus_clt /usr/local/bin/platypus;
cp Platypus-5.1/Platypus.app/Contents/Resources/ScriptExec /usr/local/share/platypus/ScriptExec;
cp -r Platypus-5.1/Platypus.app/Contents/Resources/MainMenu.nib /usr/local/share/platypus/MainMenu.nib;
chmod -R 755 /usr/local/share/platypus;

# -- Get brew
#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";

brew update cmake || brew install cmake;

LLVMVER=3.9.0
OSXVER=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')

PRIMESIEVELOC=https://dl.bintray.com/kimwalisch/primesieve/;
PRIMESIEVEFILE=primesieve-5.6.0;

DOWNLOAD=https://github.com/uclatommy/travis-homebrew-bottle/releases/download/v1.0-beta/
PYTHON3BOTTLE=python3-3.5.2_3.el_capitan.bottle.1.tar.gz;
HDF5BOTTLE=hdf5-1.8.17.el_capitan.bottle.tar.gz;
VALGRINDBOTTLE=valgrind-3.12.0.el_capitan.bottle.1.tar.gz;
BOOSTBOTTLE=boost-1.62.0.el_capitan.bottle.1.tar.gz;
BOOSTPYTHONBOTTLE=boost-python-1.62.0.el_capitan.bottle.1.tar.gz;

# -- Install xcode developer tools
xcode-select --install;

# -- Install llvm 3.9 and clang
if [ ! -f clang+llvm-$LLVMVER-x86_64-apple-darwin.tar.xz ] ; then
    curl -L -O http://llvm.org/releases/$LLVMVER/clang+llvm-$LLVMVER-x86_64-apple-darwin.tar.xz;
fi
tar -xf clang+llvm-$LLVMVER-x86_64-apple-darwin.tar.xz;
chmod 744 clang+llvm-$LLVMVER-x86_64-apple-darwin /usr/local/llvm;
if [ -d /usr/local/llvm ] ; then
    rm -rf /usr/local/llvm;
fi
mkdir /usr/local/llvm;
mv clang+llvm-$LLVMVER-x86_64-apple-darwin /usr/local/llvm;

# -- Install Valgrind
curl -L -O ${DOWNLOAD}${VALGRINDBOTTLE};
brew unlink valgrind;
brew install ${VALGRINDBOTTLE};

SDK_PATH=$(python -c "import os; print(os.path.realpath(os.path.dirname('$(xcrun --show-sdk-path)')))");
MACOS_SDK="-mmacosx-version-min=$OSXVER";
SYSROOT="$SDK_PATH/MacOSX$OSXVER.sdk"

# -- Get openssl (pip requires it)
brew install openssl;

# -- Build googletest
if [ ! -d googletest ] ; then
    git clone https://github.com/google/googletest.git;
fi
pushd googletest/googletest;
cmake \
. \
-DCMAKE_C_COMPILER=/usr/local/llvm/bin/clang \
-DCMAKE_CXX_COMPILER=/usr/local/llvm/bin/clang++ \
-DCMAKE_OSX_DEPLOYMENT_TARGET=$OSXVER \
-DCMAKE_OSX_SYSROOT="$SYSROOT" \
-DCMAKE_C_FLAGS_RELEASE="-DNDEBUG" \
-DCMAKE_CXX_FLAGS_RELEASE="-DNDEBUG -std=c++1y" \
-DCMAKE_INSTALL_PREFIX=/usr/local/gtest \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_COLOR_MAKEFILE=ON;
make all;
make install;
popd;

# -- Build primesieve
if [ ! -f ${PRIMESIEVEFILE}.tar.gz ] ; then
    curl -O -L ${PRIMESIEVELOC}${PRIMESIEVEFILE}.tar.gz;
fi
if [ -d ${PRIMESIEVEFILE} ] ; then
    rm -rf ${PRIMESIEVEFILE};
fi
tar -xf ${PRIMESIEVEFILE}.tar.gz;
pushd ${PRIMESIEVEFILE};
./configure \
--prefix=/usr/local/primesieve \
--enable-shared=no \
--with-sysroot="$SYSROOT" \
CC=/usr/local/llvm/bin/clang \
CXX=/usr/local/llvm/bin/clang++ \
LDFLAGS="$MACOS_SDK -stdlib=libc++" \
CPPFLAGS="$MACOS_SDK" \
CFLAGS="$MACOS_SDK";
make;
make install;
popd;

# -- Install Python3
curl -O -L ${DOWNLOAD}${PYTHON3BOTTLE};
brew unlink python3;
brew install ${PYTHON3BOTTLE};

# -- Install hdf5
curl -O -L ${DOWNLOAD}${HDF5BOTTLE};
brew tap homebrew/science;
brew install ${HDF5BOTTLE};

# -- Install Boost
curl -O -L ${DOWNLOAD}${BOOSTBOTTLE};
brew unlink boost
brew install ${BOOSTBOTTLE}

# -- Build Boost Python
curl -O -L ${DOWNLOAD}${BOOSTPYTHONBOTTLE};
brew install ${BOOSTPYTHONBOTTLE};
