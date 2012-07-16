module IB
  module Messages
    module Incoming

      MarketDepth =
          def_message 12, [:request_id, :int],
                      [:position, :int], # The row Id of this market depth entry.
                      [:operation, :int], # How it should be applied to the market depth:
                      #   0 = insert this new order into the row identified by :position
                      #   1 = update the existing order in the row identified by :position
                      #   2 = delete the existing order at the row identified by :position
                      [:side, :int], # side of the book: 0 = ask, 1 = bid
                      [:price, :decimal],
                      [:size, :int]

      class MarketDepth
        def side
          @data[:side] == 0 ? :ask : :bid
        end

        def operation
          @data[:operation] == 0 ? :insert : @data[:operation] == 1 ? :update : :delete
        end

        def to_human
          "<#{self.message_type}: #{operation} #{side} @ "+
              "#{position} = #{price} x #{size}>"
        end
      end

      MarketDepthL2 =
          def_message 13, MarketDepth, # Fields descriptions - see above
                      [:request_id, :int],
                      [:position, :int],
                      [:market_maker, :string], # The exchange hosting this order.
                      [:operation, :int],
                      [:side, :int],
                      [:price, :decimal],
                      [:size, :int]


    end # module Incoming
  end # module Messages
end # module IB
