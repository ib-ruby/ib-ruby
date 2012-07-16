module IB
  def self.db_backed?
    !!defined?(IB::DB)
  end
 
  def self.rails?
    !!defined?(Rails) && Rails.respond_to?('env')
  end

end # module IB

IbRuby = IB
Ib = IB

# IB Models can be either lightweight (tableless) or database-backed.
# By default there is no DB backend, unless specifically requested
# require 'ib/db' # to make all IB models database-backed

if IB.rails?
  require 'ib/engine'
else
  require 'ib/requires'
end
