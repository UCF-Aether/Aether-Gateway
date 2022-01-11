#!/bin/bash
# Followed: https://catalog.us-east-1.prod.workshops.aws/v2/workshops/b95a6659-bd4f-4567-8307-bddb43a608c4/en-US/700-advanced/dyigw-rak2245

spi_file=./deps/lgw/platform-rpi/libloragw/src/loragw_spi.native.c
temp_dir=/tmp/aether-gateway
cfg_dir=/etc/aether

function cleanup {
  rm -rf $temp_dir
}

set -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Gateway id function from: https://github.com/RAKWireless/rak_common_for_gateway/blob/master/rak/rak/shell_script/rak_common.sh
get_gw_id() {
    GATEWAY_EUI_NIC="eth0"
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="wlan0"
    fi
        if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="usb0"
    fi

    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
       echo ""
    fi
    GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
    GATEWAY_EUI=${GATEWAY_EUI^^}
    echo $GATEWAY_EUI
}

trap cleanup EXIT TERM QUIT INT

chmod 755 init.sh
mkdir -p $temp_dir
cd $temp_dir

git clone https://github.com/lorabasics/basicstation
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

# Create Aether config dir, and copy files
mkdir -p $cfg_dir
cat ./station.json | sed "s/<GATEWAY_EUI>/$(get_gw_id)/" > $cfg_dir/station.json
cp -f ./basicstation.service /etc/systemd/systemd
cp -f ./init.sh $cfg_dir

# Reload service spi_files 
systemctl daemon-reload
systemctl enable basicstation
systemctl start basicstation
