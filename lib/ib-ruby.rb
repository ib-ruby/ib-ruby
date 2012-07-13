module IB

  def self.db_backed?
    !!defined?(IB::DB)
  end

  # IB Models can be either lightweight (tableless) or database-backed.
  # By default there is no DB backend, unless specifically requested
  # require 'ib-ruby/db' # to make all IB models database-backed

  require 'ib-ruby/version'
  require 'ib-ruby/extensions'
  require 'ib-ruby/errors'
  require 'ib-ruby/constants'
  require 'ib-ruby/connection'

  require 'ib-ruby/models'
  require 'ib-ruby/messages'
  require 'ib-ruby/symbols'

end # module IB
IbRuby = IB
Ib = IB
