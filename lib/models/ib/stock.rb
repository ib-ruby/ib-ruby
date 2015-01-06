require 'models/ib/contract'
module IB
  class Stock < Contract
    validates_format_of :sec_type, :with => /\Astock\z/,
      :message => "should be a Stock"
    def default_attributes
      super.merge :sec_type => :stock, currency:'USD', exchange:'SMART'
    end

  end
  end

