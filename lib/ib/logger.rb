require "logger"
module LogDev
	# define default_logger 
	def default_logger
		@default_logger ||=  Logger.new(STDOUT).tap do |l|
			l.formatter = proc do |severity, datetime, progname, msg|
				#   "#{datetime.strftime("%d.%m.(%X)")}#{"%5s" % severity}->#{progname}##{msg}\n"
				## the default logger displays the message only
				msg.to_s + "\n"
			end
			l.level = Logger::INFO
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
end # module
