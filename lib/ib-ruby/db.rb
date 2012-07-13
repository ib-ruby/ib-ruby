# By requiring this file, we make all IB:Models database-backed ActiveRecord subclasses

require 'active_record'

module IB
  module DB

    def self.logger= logger
      ActiveRecord::Base.logger = logger
    end

    # Establish DB connection and do other plumbing here
    def self.connect config
      #log.warn "Starting Database connection"
      ActiveRecord::Base.establish_connection(config)
      #ActiveRecord.colorize_logging = false

      # Get rid of nasty conversion issues
      ActiveRecord::Base.default_timezone = :utc
      Time.zone = 'UTC'
    end

  end # module DB
end
