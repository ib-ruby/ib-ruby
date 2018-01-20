#require 'models/ib/contract'
module IB
  class Future  < Contract
    validates_format_of :sec_type, :with => /\Afuture\z/,
      :message => "should be a Future"
    def default_attributes
      super.merge :sec_type => :future, currency:'USD'
    end
    def to_human
      "<Future: " + [symbol, expiry, currency].join(" ") + ">"
    end

  end
  end

