# By requiring this file, we make all IB:Models database-backed ActiveRecord subclasses

require 'active_record'

module IB
  module DB

    def self.logger= logger
      ActiveRecord::Base.logger = logger
    end

    # Use this method to establish DB connection unless you're running on Rails
    def self.connect config

      # Use ib prefix for all DB tables
      ActiveRecord::Base.table_name_prefix = "ib_"

      # Get rid of nasty conversion issues
      ActiveRecord::Base.default_timezone = :utc
      Time.zone = 'UTC'

      ActiveRecord::Base.establish_connection(config)
      #ActiveRecord.colorize_logging = false
    end

  end # module DB
end

# You may just require 'ib/db', it will then auto-require core 'ib' for you
require 'ib'

