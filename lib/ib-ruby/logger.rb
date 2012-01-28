require "logger"

# Add universally accessible log method/accessor into Object
def log *args
  @@logger ||= Logger.new(STDOUT).tap do |logger|
    logger.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S.%3N')} #{msg}\n"
    end
    logger.level = Logger::INFO
  end

  @@logger.tap do |logger|
    logger.fatal *args unless args.empty?
  end
end












