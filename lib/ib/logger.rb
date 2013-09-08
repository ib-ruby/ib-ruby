require "logger"

# Add default_logger accessor into Object
def default_logger
  @default_logger ||= Logger.new(STDOUT).tap do |logger|
    time_format = RUBY_VERSION =~ /1\.8\./ ? '%H:%M:%S.%N' : '%H:%M:%S.%3N'
    logger.formatter = proc do |level, time, prog, msg|

      "#{time.strftime(time_format)} #{msg}\n"
    end
    logger.level = Logger::INFO
  end
end

def default_logger= logger
  @default_logger = logger
end

# Add universally accessible log method/accessor into Object
def log *args
  default_logger.tap do |logger|
    logger.fatal *args unless args.empty?
  end
end
