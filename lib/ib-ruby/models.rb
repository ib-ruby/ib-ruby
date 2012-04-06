module IB
  module Models

    # IB Models can be either database-backed, or not
    # require 'ib-ruby/db' # to make all IB models database-backed
    if DB
      require 'ib-ruby/models/db_model'
      Model = DBModel # All IB Models will be subclassed from ActiveRecord::Base
    else
      require 'ib-ruby/models/model'
    end

    require 'ib-ruby/models/contracts'
    # Flatten namespace (IB::Models::Option instead of IB::Models::Contracts::Option)
    include Contracts

    require 'ib-ruby/models/order'
    require 'ib-ruby/models/combo_leg'
    require 'ib-ruby/models/execution'
    require 'ib-ruby/models/bar'

  end
end

