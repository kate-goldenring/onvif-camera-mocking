#!/bin/bash
# Ask wsdd nicely to terminate.
if [ $# -eq 0 ]; then
    echo "No interface such as 'eth0' or 'eno1' provided"
    exit 1
fi
interface=$1
if [[ "$2" != "" ]]; then
    directory="$2"
else
    echo "No scripts directory provided. Using the directory the script was executed from: $( pwd )"
    directory="$( pwd )"
fi
if [[ "$3" != "" ]]; then
    firmware_ver="$3"
else
    echo "No firmware version provided. Using default 1.0"
    firmware_ver="1.0"
fi
if pgrep wsdd > /dev/null; then
    sudo pkill wsdd
fi

# Forcibly terminate.
if pgrep wsdd > /dev/null; then
    sudo pkill -9 wsdd
fi

# Ask onvif server nicely to terminate.
if pgrep onvif_srvd > /dev/null; then
    sudo pkill onvif_srvd
fi

# Forcibly terminate.
if pgrep onvif_srvd > /dev/null; then
    sudo pkill -9 onvif_srvd
fi

# Ask onvif server nicely to terminate.
if pgrep rtsp-feed.py > /dev/null; then
    sudo pkill rtsp-feed.py
fi

# Forcibly terminate.
if pgrep rtsp-feed.py > /dev/null; then
    sudo pkill -9 rtsp-feed.py
fi

ip4=$(/sbin/ip -o -4 addr list $interface | awk '{print $4}' | cut -d/ -f1)
sudo $directory/onvif_srvd/onvif_srvd  --ifs $interface --scope onvif://www.onvif.org/name/TestDev --scope onvif://www.onvif.org/Profile/S --name RTSP --width 800 --height 600 --url rtsp://$ip4:8554/stream1 --type MPEG4 --firmware_ver $firmware_ver
$directory/wsdd/wsdd  --if_name $interface --type tdn:NetworkVideoTransmitter --xaddr http://%s:1000/onvif/device_service --scope "onvif://www.onvif.org/name/Unknown onvif://www.onvif.org/Profile/Streaming"
sudo $directory/rtsp-feed.py &