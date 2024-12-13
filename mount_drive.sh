if [ $# -lt 1 ]; then
    echo "VolumeID is required"
    exit 1
fi

# Get the arguments
VOLUME="$1"
mkfs.xfs -f  /dev/disk/by-id/scsi-0HC_Volume_${VOLUME}
 
mkdir /d
 
mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${VOLUME} /d
 
echo "/dev/disk/by-id/scsi-0HC_Volume_${VOLUME} /d xfs discard,nofail,defaults 0 0" >> /etc/fstab