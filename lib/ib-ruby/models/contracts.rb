module IB
  module Models
    module Contracts
    end
  end
end

require 'ib-ruby/models/contracts/contract'
require 'ib-ruby/models/contracts/option'
require 'ib-ruby/models/contracts/bag'

module IB
  module Models
    # This module contains Contract subclasses
    module Contracts
      # Specialized Contract subclasses representing different security types
      TYPES = Hash.new(Contract)
      TYPES[IB::SECURITY_TYPES[:bag]] = Bag
      TYPES[IB::SECURITY_TYPES[:option]] = Option
    end
  end
end
