#!/usr/bin/env python
# Run privileged: `sudo /usr/bin/python3 rtsp-feed.py`

import sys
import gi

gi.require_version('Gst', '1.0')
gi.require_version('GstRtspServer', '1.0')
from gi.repository import Gst, GstRtspServer, GObject, GLib

loop = GLib.MainLoop()
Gst.init(None)

class TestRtspMediaFactory(GstRtspServer.RTSPMediaFactory):
    def __init__(self):
        GstRtspServer.RTSPMediaFactory.__init__(self)

    def do_create_element(self, url):
        global color
        mock_pipeline = "videotestsrc pattern=bar horizontal-speed=2 background-color=9228238 foreground-color={0} ! x264enc ! queue ! rtph264pay name=pay0 config-interval=1 pt=96".format(color) 
        print ("Pipeling launching: " + mock_pipeline)
        return Gst.parse_launch(mock_pipeline)

class GstreamerRtspServer():
    def __init__(self):
        self.rtspServer = GstRtspServer.RTSPServer()
        factory = TestRtspMediaFactory()
        factory.set_shared(True)
        mountPoints = self.rtspServer.get_mount_points()
        mountPoints.add_factory("/stream1", factory)
        self.rtspServer.attach(None)

# Optionally pass in video bar color in decimal format
# Choose a color: https://www.mathsisfun.com/hexadecimal-decimal-colors.html
if __name__ == '__main__':
    global color
    if len(sys.argv) > 1:
        color = sys.argv[1]
        print ("Custom chosen video bar color is " + str(color))
    else:
        color = 4080751
        print ("Default video bar color is " + str(color))
    s = GstreamerRtspServer()
    loop.run()