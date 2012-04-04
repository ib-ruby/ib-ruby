module IB
  module Models
    require 'ib-ruby/models/contracts'
    # Flatten namespace (IB::Models::Option instead of IB::Models::Contracts::Option)
    include Contracts

    require 'ib-ruby/models/order'
    require 'ib-ruby/models/combo_leg'
    require 'ib-ruby/models/execution'
    require 'ib-ruby/models/bar'

  end
end

