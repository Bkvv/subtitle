class CueInfo
  def initialize(type)
    @type = type
    @start = @end = @sequence = nil
    @message = ""
    @start_time_units = []
    @end_time_units = []
    @index = 1
  end

  attr_reader :type, :start, :end, :sequence, :message, :start_time_units, :end_time_units, :index

  def start=(start)
    @start = start 
  end

  def end=(end_point)
    @end = end_point
  end

  def message=(msg)
    @message = msg 
  end

  def sequence=(seq)
    @sequence = seq 
  end

  def index=(index)
    @index = index
  end

  def start_time_units=(units)
    @start_time_units = units
  end

  def end_time_units=(units)
    @end_time_units = units 
  end
end