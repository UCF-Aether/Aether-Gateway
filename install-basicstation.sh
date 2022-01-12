#!/bin/bash
# Followed: https://catalog.us-east-1.prod.workshops.aws/v2/workshops/b95a6659-bd4f-4567-8307-bddb43a608c4/en-US/700-advanced/dyigw-rak2245

spi_file=./deps/lgw/platform-rpi/libloragw/src/loragw_spi.native.c
temp_dir=/tmp/aether
cfg_dir=/etc/aether

function cleanup {
  rm -rf $temp_dir
}

set -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

trap cleanup EXIT TERM QUIT INT

rm -rf $temp_dir
mkdir -p $temp_dir
cd $temp_dir

git clone -b alarm-rpi3 https://github.com/UCF-Aether/basicstation.git
cd ./basicstation

# Make to download dependencies
make platform=rpi variant=std
make clean

rm ./build-rpi-std/lib/liblgw.a
rm ./deps/lgw/platform-rpi/libloragw/libloragw.a

# Set the correct SPI speed for RakWireless 2245/2247
sed -Ei 's/(#define[[:space:]]+SPI_SPEED[[:space:]]+)([[:digit:]]+)/\112000000/' $spi_file

# Re-make, and copy to /usr/bin
make platform=rpi variant=std
cp -f ./build-rpi-std/bin/station /usr/bin

echo "Finished making Basic Station"
