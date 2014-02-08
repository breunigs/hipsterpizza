# encoding: utf-8

class QueueToArrayWriter
  def initialize
    @log = []
  end

  def write(*args)
    @log << args
  end

  def close
  end

  def get
    r, @log = @log, []
    r
  end
end
