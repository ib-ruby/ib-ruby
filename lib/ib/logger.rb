require "logger"
module LogDev
# define default_logger 
def default_logger
  Logger.new(STDOUT).tap do |l|
    l.formatter = proc do |severity, datetime, progname, msg|
   #   "#{datetime.strftime("%d.%m.(%X)")}#{"%5s" % severity}->#{progname}##{msg}\n"
    ## the default logger displays the message only
      msg
    end
    l.level = Logger::INFO
  end
end


end # module
