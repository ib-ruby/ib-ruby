#require 'models/ib/contract'
module IB
  class Index  < Contract
    validates_format_of :sec_type, :with => /\Aind\z/,
      :message => "should be a Index"
    def default_attributes
      super.merge :sec_type => :ind
    end
    def to_human
      "<Index: " + [symbol, currency].join(" ") + ">"
    end

  end
  end

