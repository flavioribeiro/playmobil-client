class VideoSignalsController < ApplicationController

  def player
    set_video_signal
  end

  def index
    @video_signal = VideoSignal.new
  end

  # GET /video_signals/1/edit
  def edit
  end

  # POST /video_signals
  # POST /video_signals.json
  def create
    @video_signal = VideoSignal.new
    @video_signal.name = video_signal_params[:name]
    @video_signal.port = video_signal_params[:port]

    respond_to do |format|
      if @video_signal.save
        Resque.enqueue(StartIngest, @video_signal.id.to_s)
        format.html { redirect_to "/player/"+ @video_signal.id, notice: 'Video client was successfully created.' }
        format.json { render action: 'player', status: :created, location: @video_signal }
      else
        format.html { render action: 'index' }
        format.json { render json: @video_signal.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_video_signal
    @video_signal = VideoSignal.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def video_signal_params
    params.require(:video_signal).permit(:name, :port)
  end

end
