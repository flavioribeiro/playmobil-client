import gobject
gobject.threads_init()
import pygst
pygst.require("0.10")
import gst

class Client(object):
    def __init__(self):
        self.pipeline = gst.Pipeline('client')
        self.videotestsrc = self.create_element('videotestsrc', 'video')
        self.theoraenc = self.create_element('theoraenc', 'encoder')
        self.oggmux = self.create_element('oggmux', 'muxer')
        self.tcpserversink = self.create_element('tcpserversink', 'serversink')
        self.tcpserversink.set_property('host', '0.0.0.0')
        self.tcpserversink.set_property('port', 8080)

        self.pipeline.add(self.videotestsrc, self.theoraenc, self.oggmux, self.tcpserversink)
        gst.element_link_many(self.videotestsrc, self.theoraenc, self.oggmux, self.tcpserversink)

    def create_element(self, element, name):
        return gst.element_factory_make(element, name)

    def start(self):
        self.pipeline.set_state(gst.STATE_PLAYING)


client = Client()
client.start()
loop = gobject.MainLoop()
loop.run()
