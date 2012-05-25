require 'logger'

# A module that provides logger and log_file attached to an integration log file
module Loggable
  # The file that logs will go do, using the class name as a differentiator
  def log_file
    return @log_file if @log_file
    @log_file = $base_dir.join('..', 'log', "#{self.class}-integration.log")
    @log_file.dirname.mkpath
    @log_file
  end

  # The logger object so you can say logger.info to log messages
  def logger
    @logger ||= Logger.new(log_file)
  end
end

