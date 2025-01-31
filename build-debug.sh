#!/bin/sh

hstart='\e[0;33m'
hend='\e[0;37m'

header() {
  echo
  echo -e "${hstart}$1${hend}"
}

build() {
  cd debug-tool
  header "Building debug tool..."
  ./build.sh
  cp build/debug.bin ../build/
  cp build/debug-loader.bas ../build/disk
  cd ..
}

rm build/* &> /dev/null
build

header "Building debug disk..."
cp blank.dsk build/debug.dsk

iDSK build/debug.dsk -i build/disk -t 2
iDSK build/debug.dsk -i build/debug.bin -t 2

