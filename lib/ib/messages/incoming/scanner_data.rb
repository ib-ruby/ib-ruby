module IB
  module Messages
    module Incoming

      # This method receives the requested market scanner data results.
      # ScannerData contains following @data:
      # :request_id - The ID of the request to which this row is responding
      # :count - Number of data points returned (size of :results).
      # :results - an Array of Hashes, each hash contains a set of
      #            data about one scanned Contract:
      #            :contract - a full description of the contract (details).
      #            :distance - Varies based on query.
      #            :benchmark - Varies based on query.
      #            :projection - Varies based on query.
      #            :legs - Describes combo legs when scan is returning EFP.
      ScannerData = def_message [20, 3],
                                [:request_id, :int], # request id
                                [:count, :int]
      class ScannerData
        attr_accessor :results

        def load
          super

          @results = Array.new(@data[:count]) do |_|
            {:rank => socket.read_int,
             :contract =>
                 Contract.build(
                     :con_id => socket.read_int,
                     :symbol => socket.read_string,
                     :sec_type => socket.read_string,
                     :expiry => socket.read_string,
                     :strike => socket.read_decimal,
                     :right => socket.read_string,
                     :exchange => socket.read_string,
                     :currency => socket.read_string,
                     :local_symbol => socket.read_string,
                     :contract_detail =>
                         IB::ContractDetail.new(
                             :market_name => socket.read_string,
                             :trading_class => socket.read_string)),
             :distance => socket.read_string,
             :benchmark => socket.read_string,
             :projection => socket.read_string,
             :legs => socket.read_string,
            }
          end
        end
      end # ScannerData

    end # module Incoming
  end # module Messages
end # module IB
