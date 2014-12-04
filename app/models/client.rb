require "gst"

class Client
  def self.run
    Gst.init

    bin = Gst::Pipeline.new("client")
    raise "'pipeline' gstreamer plugin missing" if bin.nil?

    videotestsrc = Gst::ElementFactory.make("videotestsrc", "video")
    raise "'videotestsrc' gstreamer plugin missing" if videotestsrc.nil?

    theoraenc = Gst::ElementFactory.make("theoraenc", "encoder")
    raise "'theoraenc' gstreamer plugin missing" if theoraenc.nil?

    oggmux = Gst::ElementFactory.make("oggmux", "muxer")
    raise "'oggmux' gstreamer plugin missing" if oggmux.nil?

    tcpserversink = Gst::ElementFactory.make("tcpserversink", "serversink")
    raise "'tcpserversink' gstreamer plugin missing" if tcpserversink.nil?

    tcpserversink.host = '0.0.0.0'
    tcpserversink.port = 8080

    # add objects to the main pipeline
    bin << videotestsrc << theoraenc << oggmux << tcpserversink
    # link the elements
    videotestsrc >> theoraenc >> oggmux >> tcpserversink

    # start playing
    bin.play

    # Run event loop listening for bus messages until EOS or ERROR
    event_loop(bin)

    # stop the bin
    bin.stop
  end

  def self.event_loop(pipe)
    running = true
    bus = pipe.bus

    while running
      message = bus.poll(Gst::MessageType::ANY, Gst::CLOCK_TIME_NONE)
      raise "message nil" if message.nil?

      case message.type
      when Gst::MessageType::EOS
        running = false
      when Gst::MessageType::WARNING
        warning, debug = message.parse_warning
        puts "Debugging info: #{debug || 'none'}"
        puts "Warning: #{warning.message}"
      when Gst::MessageType::ERROR
        error, debug = message.parse_error
        puts "Debugging info: #{debug || 'none'}"
        puts "Error: #{error.message}"
        running = false
      end
    end
  end

end
