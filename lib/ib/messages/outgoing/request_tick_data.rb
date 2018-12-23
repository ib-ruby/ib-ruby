
module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros



      RequestTickByTickData =
          def_message [0, 91], :request_id,
                      [:contract, :serialize_short, :primary_exchange],  # include primary exchange in request
											:tick_type,  # a string  supported: "Last", "AllLast", "BidAsk" or "MidPoint".

									# ServerVersion  Version > 140  (actual supporting Version 137)
											 :number_of_ticks,  # int
											 :ignore_size      # bool
											#
      CancelTickByTickData =
          def_message [0, 97], :request_id
    end
  end
end
