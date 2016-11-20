#!/bin/bash
set -x #verbose
set -e #exit on error

if [ ! -d cache ]; then
    mkdir cache;
fi;
pushd cache;

if [ ! -f aria2-1.19.3-osx-darwin.dmg ] ; then
    curl -O -L -f https://github.com/tatsuhiro-t/aria2/releases/download/release-1.19.3/aria2-1.19.3-osx-darwin.dmg;
fi
hdiutil attach aria2-1.19.3-osx-darwin.dmg;
sudo installer -package "/Volumes/aria2 1.19.3 Intel/aria2.pkg" -target /;
if [ ! -f SDL2-2.0.4.dmg ] ; then
    curl -O -L -f https://www.libsdl.org/release/SDL2-2.0.4.dmg;
fi
if [ ! -f SDL2_image-2.0.1.dmg ] ; then
    curl -O -L -f https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.1.dmg;
fi
if [ ! -f SDL2_mixer-2.0.1.dmg ] ; then
    curl -O -L -f https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.1.dmg;
fi
if [ ! -f SDL2_ttf-2.0.13.dmg ] ; then
    curl -O -L -f https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.13.dmg;
fi
if [ ! -f gstreamer-1.0-1.7.1-x86_64.pkg ] ; then
    /usr/local/aria2/bin/aria2c -x 10 http://gstreamer.freedesktop.org/data/pkg/osx/1.7.1/gstreamer-1.0-1.7.1-x86_64.pkg;
fi
if [ ! -f gstreamer-1.0-devel-1.7.1-x86_64.pkg ] ; then
    /usr/local/aria2/bin/aria2c -x 10 http://gstreamer.freedesktop.org/data/pkg/osx/1.7.1/gstreamer-1.0-devel-1.7.1-x86_64.pkg;
fi
if [ ! -f platypus.zip ] ; then
    curl -O -L -f http://www.sveinbjorn.org/files/software/platypus.zip;
fi
if [ ! -f Keka-1.0.4-snow.dmg ] ; then
    curl -O -L -f http://download.kekaosx.com/snow/Keka-1.0.4-snow.dmg;
fi
hdiutil attach Keka-1.0.4-snow.dmg;
hdiutil attach SDL2-2.0.4.dmg;
sudo cp -a /Volumes/SDL2/SDL2.framework /Library/Frameworks/ || echo "Continuing...";
hdiutil attach SDL2_image-2.0.1.dmg;
sudo cp -a /Volumes/SDL2_image/SDL2_image.framework /Library/Frameworks/ || echo "Continuing...";
hdiutil attach SDL2_ttf-2.0.13.dmg;
sudo cp -a /Volumes/SDL2_ttf/SDL2_ttf.framework /Library/Frameworks/ || echo "Continuing...";
hdiutil attach SDL2_mixer-2.0.1.dmg;
sudo cp -a /Volumes/SDL2_mixer/SDL2_mixer.framework /Library/Frameworks/ || echo "Continuing...";
# Note: fails to overwrite existing installation which causes python3 compile error later.
sudo installer -package gstreamer-1.0-1.7.1-x86_64.pkg -target /;
sudo installer -package gstreamer-1.0-devel-1.7.1-x86_64.pkg -target /;
unzip -o platypus.zip;
mkdir -p /usr/local/bin;
mkdir -p /usr/local/share/platypus;
mkdir -p /usr/local/man/platypus;
cp Platypus-5.1/Platypus.app/Contents/Resources/platypus_clt /usr/local/bin/platypus;
cp Platypus-5.1/Platypus.app/Contents/Resources/ScriptExec /usr/local/share/platypus/ScriptExec;
cp -r Platypus-5.1/Platypus.app/Contents/Resources/MainMenu.nib /usr/local/share/platypus/MainMenu.nib;
chmod -R 755 /usr/local/share/platypus;

# -- Update brew or download it if not installed
brew update || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";

brew upgrade cmake || brew install cmake;

LLVMVER=3.9.0
OSXVER=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')
if [ $OSXVER = 10.10 ]; then
    OSXNAME=yosemite;
elif [ $OSXVER = 10.11 ]; then
    OSXNAME=el_capitan;
elif [ $OSXVER = 10.12 ]; then
    OSXNAME=sierra;
else
    OSXNAME=unknown;
fi;

# -- Install xcode developer tools
xcode-select --install || echo "Continuing...";

# -- Install llvm 3.9 and clang
if [ ! -f clang+llvm-$LLVMVER-x86_64-apple-darwin.tar.xz ] ; then
    curl -L -O -f http://llvm.org/releases/$LLVMVER/clang+llvm-$LLVMVER-x86_64-apple-darwin.tar.xz;
fi
tar -xf clang+llvm-$LLVMVER-x86_64-apple-darwin.tar.xz;
if [ -d /usr/local/llvm ] ; then
    rm -rf /usr/local/llvm;
fi
mv clang+llvm-$LLVMVER-x86_64-apple-darwin /usr/local/llvm;
chmod 744 /usr/local/llvm;
if [ -f /usr/local/bin/clang ]; then
    rm -rf /usr/local/bin/clang;
fi;
if [ -f /usr/local/bin/clang++ ]; then
    rm -rf /usr/local/bin/clang++;
fi;
ln -s /usr/local/llvm/bin/clang /usr/local/bin/clang;
ln -s /usr/local/llvm/bin/clang++ /usr/local/bin/clang++;

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
-DCMAKE_C_FLAGS_RELEASE="-DNDEBUG" \
-DCMAKE_CXX_FLAGS_RELEASE="-DNDEBUG -std=c++1y" \
-DCMAKE_INSTALL_PREFIX=/usr/local/gtest \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_COLOR_MAKEFILE=ON;
make all;
make install;
popd;

# -- Build primesieve
PRIMESIEVELOC=https://dl.bintray.com/kimwalisch/primesieve/;
PRIMESIEVEFILE=primesieve-5.6.0;
if [ ! -f ${PRIMESIEVEFILE}.tar.gz ] ; then
    curl -O -L -f ${PRIMESIEVELOC}${PRIMESIEVEFILE}.tar.gz;
fi
if [ -d ${PRIMESIEVEFILE} ] ; then
    rm -rf ${PRIMESIEVEFILE};
fi
tar -xf ${PRIMESIEVEFILE}.tar.gz;
pushd ${PRIMESIEVEFILE};
./configure \
--prefix=/usr/local/primesieve \
--enable-shared=no \
CC=/usr/local/llvm/bin/clang \
CXX=/usr/local/llvm/bin/clang++ \
LDFLAGS="$MACOS_SDK -stdlib=libc++" \
CPPFLAGS="$MACOS_SDK" \
CFLAGS="$MACOS_SDK";
make;
make install;
popd;

DOWNLOAD=https://github.com/uclatommy/travis-homebrew-bottle/releases/download/v1.1-beta/

# -- Install Valgrind
VALGRIND=3.12.0
VALGRINDBOTTLE=valgrind-${VALGRIND}.${OSXNAME}.bottle.1.tar.gz;
BUILDVALGRIND=false;
OMITVALGRIND=false;
curl -O -L -f ${DOWNLOAD}${VALGRINDBOTTLE} || brew install $(ls valgrind-${VALGRIND}.${OSXNAME}.bottle*tar.gz) || BUILDVALGRIND=true;
if [ "$BUILDVALGRIND" = true ]; then
    rm -f ${VALGRINDBOTTLE};
    brew uninstall --force valgrind || echo "Continuing...";
    RETRY=false;
    brew install --build-bottle valgrind || RETRY=true;
    if [ "$RETRY" = true ]; then
        VALGRIND=HEAD;
        brew install --build-bottle --HEAD valgrind || OMITVALGRIND=true;
    fi;
    if [ ! -d valgrind-$VALGRIND ] && [ "$OMITVALGRIND" = false ]; then
        brew unpack --patch --destdir=. valgrind;
    fi;
    if [ "$OMITVALGRIND" = false ]; then
        pushd valgrind-$VALGRIND;
        ./autogen.sh;
        ./configure --disable-dependency-tracking --prefix=/usr/local/Cellar/valgrind/$VALGRIND --enable-only64bit --build=amd64-darwin CC=/usr/local/llvm/bin/clang CXX=/usr/local/llvm/bin/clang++;
        make;
        make install;
        brew link --overwrite valgrind;
        popd;
        brew bottle valgrind;
    fi;
fi;
if [ "$OMITVALGRIND" = false ]; then
    brew unlink valgrind || echo "Continuing...";
    brew install ${VALGRINDBOTTLE};
    brew link --overwrite valgrind;
fi;

SDK_PATH=$(python -c "import os; print(os.path.realpath(os.path.dirname('$(xcrun --show-sdk-path)')))");
MACOS_SDK="-mmacosx-version-min=$OSXVER";
SYSROOT="$SDK_PATH/MacOSX$OSXVER.sdk"

# -- Get openssl (pip requires it)
brew upgrade openssl || brew install openssl;
brew link --force openssl;
brew upgrade readline || brew install readline;
brew link --force readline;
brew upgrade pyenv || brew install pyenv;
brew link --force pyenv;
brew upgrade sqlite3 || brew install sqlite3;
brew link --force sqlite3;

# -- Install Python3
BUILDPYTHON=false;
PYTHON=3.5.2;
PYTHONVER=${PYTHON}_3; #brew's python formula puts that _3 to denote that it can be used to build a bottle
PYTHON3BOTTLE=python3-${PYTHONVER}.${OSXNAME}.bottle.1.tar.gz;
curl -O -L -f ${DOWNLOAD}${PYTHON3BOTTLE} || brew install $(ls python3-${PYTHONVER}.${OSXNAME}.bottle*tar.gz) || BUILDPYTHON=true;
if [ "$BUILDPYTHON" = true ]; then
    brew uninstall --force python3 || echo "Continuing...";
    brew install --build-bottle python3;
    if [ ! -d python3-$PYTHON ] ; then
        brew unpack --patch --destdir=. python3;
    fi;
    pushd python3-$PYTHON;
    CC=/usr/local/llvm/bin/clang;
    CXX=/usr/local/llvm/bin/clang++;
    LDFLAGS="$MACOS_SDK -L$(brew --prefix openssl)/lib -L$(brew --prefix sqlite3)/lib";
    CPPFLAGS="-pipe -w -Os -march=native -isystem/usr/local/include -isystem/usr/include/libxml2 -isystem/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers -I$(brew --prefix readline)/include -I$(brew --prefix sqlite3)/include -I$(brew --prefix openssl)/include $MACOS_SDK" ;
    CFLAGS="-pipe -w -Os -march=native -isystem/usr/local/include -isystem/usr/include/libxml2 -isystem/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers -I$(brew --prefix readline)/include -I$(brew --prefix sqlite3)/include -I$(brew --prefix openssl)/include $MACOS_SDK";
    MACOSX_DEPLOYMENT_TARGET=$OSXVER;
    if [ "$OMITVALGRIND" = false ]; then
        ./configure --prefix=/usr/local/Cellar/python3/$PYTHONVER --enable-ipv6 --datarootdir=/usr/local/Cellar/python3/$PYTHONVER/share --datadir=/usr/local/Cellar/python3/$PYTHONVER/share --enable-shared --with-ensurepip --without-gcc --with-valgrind;
    else
        ./configure --prefix=/usr/local/Cellar/python3/$PYTHONVER --enable-ipv6 --datarootdir=/usr/local/Cellar/python3/$PYTHONVER/share --datadir=/usr/local/Cellar/python3/$PYTHONVER/share --enable-shared --with-ensurepip --without-gcc;
    fi;
    make;
    make install PYTHONAPPSDIR=/usr/local/Cellar/python3/$PYTHONVER;
    brew link --overwrite python3;
    popd;
    brew bottle python3;
fi;
brew unlink python3 || echo "Continuing...";
brew install ${PYTHON3BOTTLE};
brew link --overwrite python3;
pip3 install --upgrade pip setuptools wheel;

# -- Install hdf5
BUILDHDF5=false;
HDF5=1.8.17
HDF5BOTTLE=hdf5-${HDF5}.${OSXNAME}.bottle.tar.gz;
curl -O -L -f ${DOWNLOAD}${HDF5BOTTLE} || brew install $(ls hdf5-${HDF5}.${OSXNAME}.bottle*tar.gz) || BUILDHDF5=true;
brew tap homebrew/science;
if [ "$BUILDHDF5" = true ]; then
    brew uninstall --force hdf5 || echo "Continuing...";
    brew install --build-bottle hdf5;
    if [ ! -d hdf5-$HDF5 ] ; then
        brew unpack --patch --destdir=. hdf5;
    fi;
    pushd hdf5-$HDF5;
    ./configure --prefix=/usr/local/Cellar/hdf5/$HDF5 --enable-production --enable-debug=no --disable-dependency-tracking --with-zlib=/usr --with-szlib=/usr/local/opt/szip --enable-static=yes --enable-shared=yes --enable-cxx --disable-fortran CC=/usr/local/llvm/bin/clang CXX=/usr/local/llvm/bin/clang++ CFLAGS="$MACOS_SDK" CPPFLAGS="$MACOS_SDK" LDFLAGS="$MACOS_SDK";
    make;
    make install;
    popd;
    brew bottle hdf5;
fi;
brew unlink hdf5 || echo "Continuing...";
brew install ${HDF5BOTTLE} || brew install hdf5-${HDF5}.${OSXNAME}.bottle*tar.gz;
brew link --overwrite hdf5;

# -- Install Boost
BOOSTVER=1.62.0;
BUILDBOOST=false
BOOSTOVERRIDE=true #set to true if you want to use vanilla boost.
BOOSTBOTTLE=boost-${BOOSTVER}.${OSXNAME}.bottle.1.tar.gz;
curl -O -L -f ${DOWNLOAD}${BOOSTBOTTLE} || brew install $(ls boost-${BOOSTVER}.${OSXNAME}.bottle*tar.gz) || BUILDBOOST=true;
if [ "$BUILDBOOST" = true ] && [ "$BOOSTOVERRIDE" = false ]; then
    brew uninstall --force boost || echo "Continuing...";
    brew install --build-bottle boost --c++11;
    if [ ! -d boost-$BOOSTVER ]; then
        brew unpack --patch --destdir=. boost;
    fi
    pushd boost-$BOOSTVER;
    ./bootstrap.sh --prefix=/usr/local/Cellar/boost/$BOOSTVER --libdir=/usr/local/Cellar/boost/$BOOSTVER/lib --without-icu --without-libraries=python,mpi > boost_bootstrap.log;
    {
    echo "using darwin : : /usr/local/llvm/bin/clang++"
    echo "             : <cxxflags>$MACOS_SDK <linkflags>$MACOS_SDK <compileflags>$MACOS_SDK ;"
    echo "using python : 3.5"
    echo "             : /usr/local/bin/python3.5"
    echo "             : /usr/local/Cellar/python3/$PYTHONVER/include/python3.5m ;"
    } > user-config.jam;
    ./b2 headers;
    ./b2 --prefix=/usr/local/Cellar/boost/$BOOSTVER --libdir=/usr/local/Cellar/boost/$BOOSTVER/lib -d2 -j4 --layout=tagged --user-config=user-config.jam install threading=multi,single link=shared,static;
    popd;
    brew link --overwrite boost;
    brew bottle boost;
else
    if [ "$BOOSTOVERRIDE" = true ]; then
        brew upgrade boost || brew install boost;
    else
        brew unlink boost || echo "Continuing...";
        brew install ${BOOSTBOTTLE} || brew install boost-${BOOSTVER}.${OSXNAME}.bottle*tar.gz;
        brew link --overwrite boost;
    fi;
fi;


# -- Build Boost Python
BUILDBOOSTPYTHON=false
BOOSTPYTHONBOTTLE=boost-python-${BOOSTVER}.${OSXNAME}.bottle.1.tar.gz;
curl -O -L -f ${DOWNLOAD}${BOOSTPYTHONBOTTLE} || brew install $(ls boost-python-${BOOSTVER}.${OSXNAME}.bottle*tar.gz) || BUILDBOOSTPYTHON=true;
if [ "$BUILDBOOSTPYTHON" = true ]; then
    brew uninstall --force boost-python || echo "Continuing...";
    brew install --build-bottle boost-python --c++11 --with-python3 --without-python;
    if [ ! -d boost-python-$BOOSTVER ]; then
        brew unpack --patch --destdir=. boost-python;
    fi;
    pushd boost-python-$BOOSTVER
    ./bootstrap.sh --prefix=/usr/local/Cellar/boost-python/$BOOSTVER --libdir=/usr/local/Cellar/boost-python/$BOOSTVER/lib --with-libraries=python --with-python=python3 --with-python-root=/usr/local/Cellar/python3/$PYTHONVER;
    {
    echo "using darwin : : /usr/local/llvm/bin/clang++"
    echo "             : <cxxflags>$MACOS_SDK <linkflags>$MACOS_SDK <compileflags>$MACOS_SDK ;"
    echo "using python : 3.5"
    echo "             : /usr/local/bin/python3.5"
    echo "             : /usr/local/Cellar/python3/$PYTHONVER/include/python3.5m ;"
    } > user-config.jam;
    ./b2 --build-dir=build-python3 --stagedir=stage-python3 python=3.5 --prefix=/usr/local/Cellar/boost-python/$BOOSTVER --libdir=/usr/local/Cellar/boost-python/$BOOSTVER/lib -d2 -j4 --layout=tagged --user-config=user-config.jam threading=multi,single link=shared,static install;
    brew link --overwrite boost-python;
    popd;
    brew bottle boost-python;
fi;
brew unlink boost-python || echo "Continuing...";
brew install ${BOOSTPYTHONBOTTLE} || brew install boost-python-${BOOSTVER}.${OSXNAME}.bottle*tar.gz;
brew link --overwrite boost-python;
brew info boost-python
ls -l /usr/local/Cellar/boost-python/$BOOSTVER

popd; #cache
