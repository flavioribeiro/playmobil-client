class VideoSignal
  include Mongoid::Document

  field :name, type: String
  field :port, type: Integer

  validates_presence_of :name

end
