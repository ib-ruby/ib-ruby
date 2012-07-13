module IB

  # IB Models can be either lightweight (tableless) or database-backed.
  # By default there is no DB backend, unless specifically requested
  # require 'ib-ruby/db' # to make all IB models database-backed

  if defined?(Rails) && Rails.respond_to?('env')
    require 'ib-ruby/engine'
  else
    require 'ib-ruby/requires'
  end
end # module IB
IbRuby = IB
Ib = IB
