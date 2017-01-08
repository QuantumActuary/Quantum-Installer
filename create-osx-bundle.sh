#!/bin/bash
set -x  # verbose
set -e  # exit on error

PLATYPUS=/usr/local/bin/platypus
SCRIPT_PATH="${BASH_SOURCE[0]}";
PYTHONVER=3.6.0

PYTHON=python

if([ -h "${SCRIPT_PATH}" ]) then
  while([ -h "${SCRIPT_PATH}" ]) do SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
fi

SCRIPT_PATH=$(python -c "import os; print(os.path.realpath(os.path.dirname('${SCRIPT_PATH}')))")
OSXRELOCATOR="osxrelocator"

echo "-- Create initial Kivy.app package"
if [ -d Kivy.app ]; then
    rm -rf Kivy.app;
fi;
$PLATYPUS -DBR -x -y \
    -i "$SCRIPT_PATH/data/icon.icns" \
    -a "Kivy" \
    -o "None" \
    -p "/bin/bash" \
    -V "$VERSION" \
    -I "org.kivy.osxlauncher" \
    -X "*" \
    "$SCRIPT_PATH/data/script" \
    "$SCRIPT_PATH/Kivy.app"

cp $SCRIPT_PATH/data/nogui $SCRIPT_PATH/Kivy.app/Contents/Resources/nogui

# --- Frameworks

echo "-- Get TitanDB-0.5.4"
if [! -d cache ]; then
    mkdir cache;
fi
pushd cache;
if [ ! -f cache/titan-0.5.4-hadoop2.zip ]; then
    curl -O -L -f http://s3.thinkaurelius.com/downloads/titan/titan-0.5.4-hadoop2.zip;
fi;
unzip -o titan-0.5.4-hadoop2.zip;
popd;

echo "-- Create Frameworks directory"
mkdir -p Kivy.app/Contents/Frameworks

pushd Kivy.app/Contents/Frameworks

echo "-- Copy frameworks"
cp -a /Library/Frameworks/GStreamer.framework .
cp -a /Library/Frameworks/SDL2.framework .
cp -a /Library/Frameworks/SDL2_image.framework .
cp -a /Library/Frameworks/SDL2_ttf.framework .
cp -a /Library/Frameworks/SDL2_mixer.framework .
cp -a ${SCRIPT_PATH}/cache/titan-0.5.4-hadoop2 .

echo "-- Reduce frameworks size"
rm -rf {SDL2,SDL2_image,SDL2_ttf,SDL2_mixer,GStreamer}.framework/Headers
rm -rf {SDL2,SDL2_image,SDL2_ttf,SDL2_mixer}.framework/Versions/A/Headers
rm -rf SDL2_ttf.framework/Versions/A/Frameworks/FreeType.framework/Versions/A/Headers
rm -rf SDL2_ttf.framework/Versions/A/Frameworks/FreeType.framework/Versions/Current
cd SDL2_ttf.framework/Versions/A/Frameworks/FreeType.framework/Versions/
rm -rf Current
ln -s A Current
cd -
rm -rf SDL2_ttf.framework/Versions/A/Frameworks/FreeType.framework/Headers
rm -rf GStreamer.framework/Versions/1.0/share/locale
rm -rf GStreamer.framework/Versions/1.0/lib/gstreamer-1.0/static
rm -rf GStreamer.framework/Versions/1.0/share/gstreamer-1.0/validate-scenario
rm -rf GStreamer.framework/Versions/1.0/share/fontconfig/conf.avail
rm -rf GStreamer.framework/Versions/1.0/include
rm -rf GStreamer.framework/Versions/1.0/lib/gst-validate-launcher
rm -rf GStreamer.framework/Versions/1.0/Headers
rm -rf GStreamer.framework/Versions/1.0/lib/pkgconfig
rm -rf GStreamer.framework/Versions/1.0/bin
rm -rf GStreamer.framework/Versions/1.0/etc
rm -rf GStreamer.framework/Versions/1.0/share/gstreamer
find -E . -regex '.*\.a$' -exec rm {} \;
find -E . -regex '.*\.la$' -exec rm {} \;
find -E . -regex '.*\.exe$' -exec rm {} \;

echo "-- Remove duplicate gstreamer libraries"
$PYTHON $SCRIPT_PATH/data/link_duplicate.py GStreamer.framework/Libraries

echo "-- Remove broken symlink"
find . -type l -exec sh -c "file -b {} | grep -q ^broken" \; -print
find . -type l -exec sh -c "file -b {} | grep -q ^broken" \; -print | xargs rm

echo "-- Copy gst-plugin-scanner"
mv GStreamer.framework/Versions/Current/libexec/gstreamer-1.0/gst-plugin-scanner ../Resources

popd
echo "-- Done!";
