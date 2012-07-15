module Ib
  class Underlying < ActiveRecord::Base
    attr_accessible :con_id, :contract_id, :delta, :price
  end
end
