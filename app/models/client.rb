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

  def self.init
    Gst.init

    bin = Gst::Pipeline.new("client")
    raise "'pipeline' gstreamer plugin missing" if bin.nil?

    src = Gst::ElementFactory.make("v4l2src", "video")
    raise "'v4l2src' gstreamer plugin missing" if src.nil?
    src.device = '/dev/video0'

    tee = Gst::ElementFactory.make("tee", "tee")
    raise "'tee' gstreamer plugin missing" if tee.nil?

    preview_queue = Gst::ElementFactory.make("queue", "preview_queue")
    raise "'queue' gstreamer plugin missing" if preview_queue.nil?
    preview_queue.max-size-bytes = 134217728
    preview_queue.max-size-time = 20000000000
    preview_queue.max-size-buffers = 1000

    theoraenc = Gst::ElementFactory.make("theoraenc", "encoder")
    raise "'theoraenc' gstreamer plugin missing" if theoraenc.nil?

    oggmux = Gst::ElementFactory.make("oggmux", "muxer")
    raise "'oggmux' gstreamer plugin missing" if oggmux.nil?

    tcpserversink = Gst::ElementFactory.make("tcpserversink", "serversink")
    raise "'tcpserversink' gstreamer plugin missing" if tcpserversink.nil?

    tcpserversink.host = '0.0.0.0'
    tcpserversink.port = 8080

    # streaming elements
    stream_queue = Gst::ElementFactory.make("queue", "stream_queue")
    raise "'queue' gstreamer plugin missing" if stream_queue.nil?

    ffmpegcolorspace = Gst::ElementFactory.make("ffmpegcolorspace", "ffmpegcolorspace")
    raise "'ffmpegcolorspace' gstreamer plugin missing" if ffmpegcolorspace.nil?

    queue2 = Gst::ElementFactory.make("queue", "queue2")
    raise "'queue' gstreamer plugin missing" if queue2.nil?

    encoder2 = Gst::ElementFactory.make("x264enc", "encoder2")
    raise "'x264enc' gstreamer plugin missing" if encoder2.nil?
    encoder2.bitrate = 400

    queue3 = Gst::ElementFactory.make("queue", "queue3")
    raise "'queue' gstreamer plugin missing" if queue3.nil?

    muxer2 = Gst::ElementFactory.make("flvmux", "muxer2")
    raise "'flvmux' gstreamer plugin missing" if muxer2.nil?
    muxer2.streamable = True

    queue4 = Gst::ElementFactory.make("queue", "queue4")
    raise "'queue' gstreamer plugin missing" if queue4.nil?
    queue4.max-size-bytes = 134217728
    queue4.max-size-time = 20000000000
    queue4.max-size-buffers = 1000

    rtmpsink = Gst::ElementFactory.make("rtmpsink", "rtmpsink")
    raise "'rtmpsink' gstreamer plugin missing" if rtmpsink.nil?
    rtmpsink.location = 'rtmp://54.94.222.15/playmobil/working live=1'

    # add objects to the main pipeline
    bin << src << tee << preview_queue << theoraenc << oggmux << tcpserversink
    # link the elements
    src >> tee >> preview_queue >> theoraenc > oggmux >> tcpserversink

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



  def self.ingest_rtmp

    bin << stream_queue << ffmpegcolorspace << queue2 << encoder2 << queue3 << muxer2 << queue4 << rtmpsink
    rtmpsink.sync_state_with_parent
    queue4.sync_state_with_parent
    muxer2.sync_state_with_parent
    queue3.sync_state_with_parent
    encoder2.sync_state_with_parent
    queue2.sync_state_with_parent
    ffmpegcolorspace.sync_state_with_parent
    stream_queue.sync_state_with_parent
    stream_queue >> ffmpegcolorspace >> queue2 >> encoder2 >> queue3 >> muxer2 >> queue4 >> rtmpsink

    tee_pad = tee.get_request_pad("src%d")
    queue_video_pad = stream_queue.get_static_pad("sink")
    sys.exit(-1) if (tee_pad.link(queue_video_pad) != gst.PAD_LINK_OK)
  end


end
