# onvif-camera-mocking
This project consists of tools and instructions for mocking an ONVIF compliant IP camera and passing an RTSP stream through it.

## Steps
> Note: these steps only work on Linux and have only been tested on Ubuntu

### Get the [ONVIF server]((https://github.com/KoynovStas/onvif_srvd)) and [WS-Discovery Service](https://github.com/KoynovStas/wsdd)
The ONVIF server and WS-Discovery Service can either be copied over from a public container or built locally.
#### Option A: Copying from `onvif_build` container
Since the ONVIF server and wsdd builds are time consuming and prone to bugs, a container with the pre-built binaries is provided.
1. [Install docker](https://docs.docker.com/engine/install/ubuntu/) and pull the container
    ```
    sudo docker pull ghcr.io/kate-goldenring/onvif-build:latest
    ```

    > Note: for a mock camera that supports the ONVIF [`UpgradeSystemFirmware` endpoint](http://www.onvif.org/onvif/ver10/device/wsdl/devicemgmt.wsdl#op.UpgradeSystemFirmware) pull `ghcr.io/kate-goldenring/onvif-build-fw-upgrade:latest`
1. Run the container
    ```
    sudo docker run -d --name onvif_build ghcr.io/kate-goldenring/onvif-build:latest
    ```
    > Ensure the container is running with `docker ps -a | grep onvif_build`
1. Copy over the ONVIF server binary to the desired directory (i.e. current working directory):
    ```
    sudo docker cp onvif_build:/onvif_srvd/ ./
    ```
1. Copy over the wsdd binary to your home directory
    ```
    sudo docker cp onvif_build:/wsdd/ ./
    ```
1. Remove the docker container
    ```
    sudo docker rm onvif_build
    sudo docker rmi ghcr.io/kate-goldenring/onvif-build
    ```
#### Option B: Building
##### Build the ONVIF server using [onvif_srvd](https://github.com/KoynovStas/onvif_srvd) 

1. Install dependencies
    ```sh
    sudo apt update
    sudo apt install flex bison byacc make m4 autoconf unzip \
        git g++ wget -y
    ```
1. Clone and build the ONVIF server
    > Note a fork is being used to resolve issues getting the gsoap package

    ```sh
    git clone https://github.com/kate-goldenring/onvif_srvd.git 
    cd onvif_srvd
    git checkout gsoap-2.8.117
    make release
    ```
##### Build the [wsdd](https://github.com/KoynovStas/wsdd) WS-Discovery Service
1. Clone and build the WS-Discovery service
    > Note a fork is being used to resolve issues getting the gsoap package

    ```sh
    git clone https://github.com/kate-goldenring/wsdd.git 
    cd wsdd
    git checkout gsoap-2.8.117 
    make release
    ```
#### Option C: Building with `lxd` (coming soon)
### Start the ONVIF and Discovery services
1. Run `ifconfig` or `ipconfig` to determine your network interface. Then, pass your interface (such as `eno1`,`eth0`, `eth1`, etc) to the script. The following assumes `eth0`. 
1. Run the start script specifying the network interface and optionally the resources directory and firmware version of the camera.
    
    > The script uses the following arguments and defaults:
    > - arg1: (mandatory) the network interface
    > - arg2: (defaults to $PWD) the directory of the onvif_srvd, wsdd, and (if local) rtsp_feed.py program
    > - arg3: (defaults to 1.0) the "mock" firmware version of the camera.

    ```sh
    ./onvif-camera-mocking/scripts/start-onvif-camera.sh eth0
    ```
    Or if you'd rather 
    ```sh
    curl https://raw.githubusercontent.com/kate-goldenring/onvif-camera-mocking/main/scripts/start-onvif-camera.sh > ./start-onvif-camera.sh
    chmod +x ./start-onvif-camera.sh
    ./start-onvif-camera.sh eth0
    ```
#### Option D: Building an "all-in-one" single container for use as a Kubernetes pod
1. Ensure you have built the wsdd and onvif_srvd binaries per the instructions above and copied
them into your current working directory. 
2. Ensure you have copied rtsp-feed.py and scripts/start.sh to you current directory.
3. copy build/Dockerfile.all-in-one to Dockerfile in your curent directory
4. run docker build: 
    ```sh
    docker build -t onvif_srvd .
    ```
5. tag and push the image to your Docker repository
6. You should now be able to run this as a Kubernetes pod with the following(not this uses hostNetwork):
```
---
apiVersion: v1
kind: Pod
metadata:
  name: onvif-srvd
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
  containers:
    - name: onvif-srvd
      image: <docker-user>/onvif_srvd
      ports:
        - containerPort: 3702
          hostPort: 3702
          protocol: UDP
        - containerPort: 1000
          hostPort: 1000
          protocol: TCP
        - containerPort: 8554
          hostPort: 8554
          protocol: TCP
```
change \<docker-user\> in above to your Dockerhub user account.


### Start the ONVIF and Discovery services

### Ensure that the ONVIF camera service is running and discoverable 
Use one of the [tools recommended by onvif_srvd for testing the ONVIF service](https://github.com/KoynovStas/onvif_srvd#testing). If you have the ONVIF Device Manager installed on a Windows host on the same network as your newly mocked camera, simply open it and confirm that a new camera called "TestDev" exists.

Alternatively, the following are instructions for using a Rust tool [ONVIF-rs](https://github.com/lumeohq/onvif-rs):
1. [Install rust](https://www.rust-lang.org/tools/install)
1. Clone and run onvif-rs
    ```sh
    git clone https://github.com/lumeohq/onvif-rs.git
    cd onvif-rs
    cargo run --example discovery
    ```
    > Note: Reference [project's README](https://github.com/lumeohq/onvif-rs#troubleshooting) for troubleshooting if you encounter openssl issues.

    You should see a camera discovered with the same IP address as the machine running the ONVIF server.

### Pass an rstp feed through the "camera" (ONVIF service) 
Now that we have a camera connected to the network, lets pass some footage through it. This step can be be run as a container or locally.
#### Option A: Run as a container
1. [Install docker](https://docs.docker.com/engine/install/ubuntu/) and pull the container
    ```sh
    sudo docker pull ghcr.io/kate-goldenring/rtsp_feed:latest
    ```
1. Run the container in the background using the host's network
    ```
    sudo docker run -d --network host --name rtsp_feed ghcr.io/kate-goldenring/rtsp_feed:latest
    ```
1. If using the ONVIF Device Manager, you should now see a stream coming from the camera of a vertical bar moving horizontally.

#### Option B: Run locally
1. Install goobject instrospection libraries (not needed for Ubuntu 18.04)
    ```sh
    sudo apt-get install python3-gi
    ```
1. Install gstreamer
    ```sh
    sudo apt-get install gstreamer-1.0
    ```
1. Install gstreamer RTSP server
    ```sh
    sudo apt-get install libgstrtspserver-1.0-dev gstreamer1.0-rtsp 
    ```
1. Install the gstreamer plugins needed for x264enc of the stream
    ```sh
    sudo apt-get install gstreamer1.0-plugins-ugly
    ```
1. Run the Python program that uses `videotestsrc` to pass a fake stream through the camera of a vertical bar moving horizonally. The implementation was modified from this [StackOverflow discussion](https://stackoverflow.com/questions/59858898/how-to-convert-a-video-on-disk-to-a-rtsp-stream).
    ```sh
    sudo ./rtsp-feed.py 
    ```

    Optionally, configure the color of the feed by passing a color [in decimal format](https://www.mathsisfun.com/hexadecimal-decimal-colors.html) as an argument, such as the following for blue.
    ```sh
    sudo ./rtsp-feed.py 3093194
    ```
### Cleanup
1. Terminate the ONVIF and Discovery services
    ```sh
    ./scripts/stop-onvif-camera.sh
    ```
    Or if you'd rather 
    ```sh
    curl https://raw.githubusercontent.com/kate-goldenring/onvif-camera-mocking/main/scripts/stop-onvif-camera.sh > ./stop-onvif-camera.sh
    chmod +x ./stop-onvif-camera.sh
    ./stop-onvif-camera.sh
    ```
1. Stop your locally running python program or stop and delete your container:
    ```
    sudo docker stop rtsp_feed
    sudo docker rm rtsp_feed
    sudo docker rmi ghcr.io/kate-goldenring/rtsp_feed
    ```
