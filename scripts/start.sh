#!/bin/bash

# For use in the Kubernetes "all-in-one" conatainer i.e option D in the README

ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1 | head -1)
/usr/bin/nohup ./rtsp-feed.py > /dev/null 2>&1 &
/wsdd  --if_name eth0 --type tdn:NetworkVideoTransmitter --xaddr http://$ip4:1000/onvif/device_service --scope "onvif://www.onvif.org/name/Unknown onvif://www.onvif.org/Profile/Streaming" && \
/onvif_srvd --no_fork --ifs eth0 --scope onvif://www.onvif.org/name/TestDev --scope onvif://www.onvif.org/Profile/S --name RTSP --width 800 --height 600 --url rtsp://$ip4:8554/stream1 --type MPEG4 --firmware_ver 1
