import threading, time
import sys
import gobject
import pygst
pygst.require("0.10")
import gst

class Client(object):
    def __init__(self):
        self.pipeline = gst.Pipeline('client')

        # preview elements
        self.src = self.create_element('v4l2src', 'video')
        self.src.set_property('device', '/dev/video0')
        self.tee = gst.element_factory_make("tee", "tee")
        self.preview_queue = gst.element_factory_make("queue", "preview_queue")
        self.preview_queue.set_property('max-size-bytes', 134217728)
        self.preview_queue.set_property('max-size-time', 20000000000)
        self.preview_queue.set_property('max-size-buffers', 1000)

        self.theoraenc = self.create_element('theoraenc', 'encoder')
        self.oggmux = self.create_element('oggmux', 'muxer')
        self.tcpserversink = self.create_element('tcpserversink', 'serversink')
        self.tcpserversink.set_property('host', '0.0.0.0')
        self.tcpserversink.set_property('port', 8080)


        # streaming elements
        self.stream_queue = self.create_element('queue', 'stream_queue')
        self.ffmpegcolorspace = self.create_element('ffmpegcolorspace', 'ffmpegcolorspace')
        self.queue2 = self.create_element('queue', 'queue2')
        self.x264enc = self.create_element('x264enc', 'encoder2')
        self.x264enc.set_property('bitrate', 400)
        self.queue3 = self.create_element('queue', 'queue3')
        self.flvmux = self.create_element('flvmux', 'muxer2')
        self.flvmux.set_property('streamable', True)
        self.queue4 = self.create_element('queue', 'queue4')
        self.queue4.set_property('max-size-bytes', 134217728)
        self.queue4.set_property('max-size-time', 20000000000)
        self.queue4.set_property('max-size-buffers', 1000)
        self.rtmpsink = self.create_element('rtmpsink', 'rtmpsink')
        self.rtmpsink.set_property('location', 'rtmp://54.94.184.232/playmobil/working live=1')


        self.pipeline.add(self.src, self.tee, self.preview_queue, self.theoraenc, self.oggmux, self.tcpserversink)
        self.src.link(self.tee)
        self.tee.link(self.preview_queue)
        self.preview_queue.link(self.theoraenc)
        self.theoraenc.link(self.oggmux)
        self.oggmux.link(self.tcpserversink)

    def create_element(self, element, name):
        return gst.element_factory_make(element, name)

    def start(self):
        self.pipeline.set_state(gst.STATE_PLAYING)

    def ingest_rtmp(self):
        self.pipeline.add(self.stream_queue, self.ffmpegcolorspace, self.queue2, self.x264enc, self.queue3, self.flvmux, self.queue4, self.rtmpsink)

        self.rtmpsink.sync_state_with_parent()
        self.queue4.sync_state_with_parent()
        self.flvmux.sync_state_with_parent()
        self.queue3.sync_state_with_parent()
        self.x264enc.sync_state_with_parent()
        self.queue2.sync_state_with_parent()
        self.ffmpegcolorspace.sync_state_with_parent()
        self.stream_queue.sync_state_with_parent()

        gst.element_link_many(self.stream_queue, self.ffmpegcolorspace, self.queue2, self.x264enc, self.queue3, self.flvmux, self.queue4, self.rtmpsink)

        tee_pad = self.tee.get_request_pad("src%d")
        queue_video_pad = self.stream_queue.get_static_pad("sink")
        if (tee_pad.link(queue_video_pad) != gst.PAD_LINK_OK):
            sys.exit(-1)

RTMP = False
def g():
    pass

client = Client()
client.start()
gobject.threads_init()
loop = gobject.MainLoop()
gobject.timeout_add_seconds(1, g)
loop.run()


