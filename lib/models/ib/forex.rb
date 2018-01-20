#require 'models/ib/contract'
module IB
  class Forex  < IB::Contract
    validates_format_of :sec_type, :with => /\Aforex\z/,
      :message => "should be a Currency-Pair"
    def default_attributes
	    # Base-currency: USD
      super.merge :sec_type => :forex, currency:'USD', exchange:'IDEALPRO'
    end

  end
  end

