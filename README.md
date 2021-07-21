# onvif-camera-mocking
This project consists of tools and instructions for mocking an ONVIF compliant IP camera and passing an RTSP stream through it.

## Steps
### Build the ONVIF server using [onvif_srvd](https://github.com/KoynovStas/onvif_srvd)
1. Install dependencies
    ```sh
    sudo apt update
    sudo apt install flex bison byacc make m4 g++
    ```
1. Clone and build the ONVIF server
    ```sh
    git clone https://github.com/KoynovStas/onvif_srvd.git
    cd onvif_srvd
    make release
    ```
### Build the [wsdd](https://github.com/KoynovStas/wsdd) WS-Discovery Service
1. Clone and build the WS-Discovery service
    ```sh
    git clone https://github.com/KoynovStas/wsdd.git
    cd wsdd
    make release
    ```
### Start the ONVIF and Discovery services
1. Run `ifconfig` or `ipconfig` to determine your network interface. If it is not `eno1`, modify the script with your correct interface (such as `eth1`). 
1. Run the start script
    ```sh
    ./scripts/start-onvif-camera.sh
    ```
### Ensure that the ONVIF camera service is running and discoverable 
Use one of the [tools recommended by onvif_srvd for testing the ONVIF service](https://github.com/KoynovStas/onvif_srvd#testing). The following are instructions for using a Rust tool [ONVIF-rs](https://github.com/lumeohq/onvif-rs):
1. Clone and run onvif-rs
    ```sh
    git clone https://github.com/lumeohq/onvif-rs.git
    cd onvif-rs
    cargo run --example discovery
    ```
    > Note: Reference [project's README](https://github.com/lumeohq/onvif-rs#troubleshooting) for troubleshooting if you encounter openssl issues.

    You should see a camera discovered with the same IP address as the machine running the ONVIF server. The name of the device should be TestDev.
### Pass an rstp feed through the "camera" (ONVIF service) 
1. Run the Python program that uses `videotestsrc` to pass a fake stream through the camera of a vertical bar moving horizonally. The implementation was modified from this [StackOverflow discussion](https://stackoverflow.com/questions/59858898/how-to-convert-a-video-on-disk-to-a-rtsp-stream).
    ```sh
    sudo python3 rtsp-feed.py 
    ```

    Optionally, configure the color of the feed by passing a color [in decimal format](https://www.mathsisfun.com/hexadecimal-decimal-colors.html) as an argument, such as the following for blue.
    ```sh
    sudo python3 rtsp-feed.py 3093194
    ```

### Terminate the ONVIF and Discovery services
1. Run `ifconfig` or `ipconfig` to determine your network interface. If it is not `eno1`, modify the script with your correct interface (such as `eth1`). 
1. Run the start script
    ```sh
    ./scripts/stop-onvif-camera.sh
    ```
