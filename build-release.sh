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
  cp build/loader.bas ../build/debug.bas
  cd ..

  cd uGophy
  header "Building uGophy..."
  ./build.sh
  cp build/ugoph.bin ../build/
  cp build/loader.bas ../build/ugoph.bas
  cd ..
}

rm build/* &> /dev/null
build

# Build basic loader
header "Building loader..."
zmakebas -i 10 -s 10 -a 10 -l -p loader.bas -o build/disk

header "Building disk..."
cp blank.dsk build/release.dsk

iDSK build/release.dsk -i build/disk -t 2
iDSK build/release.dsk -i build/debug.bas -t 2
iDSK build/release.dsk -i build/debug.bin -t 2
iDSK build/release.dsk -i build/ugoph.bas -t 2
iDSK build/release.dsk -i build/ugoph.bin -t 2

