# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

dev=$1

if [[ -z "$1" ]]; then
  echo 'Enter device path'
  exit 1
fi

if [[ ! -e $dev ]]; then
  echo 'Invalid device'
  exit 1
fi

# Close mounts to $dev
pattern="$(basename $dev)."
fd $pattern /dev \
  | xargs -I _ sh -c "findmnt _ | grep -v TARGET | cut -d ' ' -f 1" \
  | xargs -I _ sh -c "umount _"

echo "Clearing device $dev"
sfdisk --delete $dev

echo "Creating partitions..."
# Create partitions
sfdisk $dev << EOF
,200M,c
;
EOF

# Format partitions
rm -rf /tmp/mksd
mkdir /tmp/mksd
cd /tmp/mksd
mkfs.vfat -I "${dev}1"
mkdir boot
mount "${dev}1" boot

mkfs.ext4 -F "${dev}2"
mkdir root
mount "${dev}2" root

# Download and extract root filesystem
echo "Downloading filesystem..."
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz
echo "Extracting..."
bsdtar -xpf ArchLinuxARM-rpi-armv7-latest.tar.gz -C root
echo "Writing filesystem to disk (this will take some time)"
echo "Watch with 'watch -d grep -e Dirty: -e Writeback: /proc/meminfo'"
sync
mv root/boot/* boot

# Cleanup
echo "Cleaning up"
umount boot root
cd -
rm -rf /tmp/mksd

echo "Finished making bootable SD card for $dev"
echo "Login as the default user 'alarm' with the password 'alarm'"
echo "The default root password is 'root'"
