module IB
end # module IB
IbRuby = IB

require 'ib-ruby/version'
require 'ib-ruby/constants'
require 'ib-ruby/connection'
require 'ib-ruby/models'
require 'ib-ruby/messages'

# TODO Where should we require this?
require 'ib-ruby/models/contract/option'

require 'ib-ruby/symbols'
