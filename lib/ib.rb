module IB
  def self.db_backed?
    !!defined?(IB::DB)
  end
end # module IB

IbRuby = IB
Ib = IB

# IB Models can be either lightweight (tableless) or database-backed.
# By default there is no DB backend, unless specifically requested
# require 'ib/db' # to make all IB models database-backed

if defined?(Rails) && Rails.respond_to?('env')
  require 'ib/engine'
else
  require 'ib/requires'
end
