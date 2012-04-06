# By requiring this file, we make all IB:Models database-backed ActiveRecord subclasses

module IB
  module DB

    # Establish DB connection and do other plumbing here
    def self.connect config
      log.warn "Starting Database connection"
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.logger = log
      #ActiveRecord.colorize_logging = false

      # Get rid of nasty conversion issues
      ActiveRecord::Base.default_timezone = :utc
      Time.zone = 'UTC'
    end
  end # module DB
end

require 'ib-ruby'

