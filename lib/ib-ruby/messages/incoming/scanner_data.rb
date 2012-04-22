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
                     :symbol => socket.read_str,
                     :sec_type => socket.read_str,
                     :expiry => socket.read_str,
                     :strike => socket.read_decimal,
                     :right => socket.read_str,
                     :exchange => socket.read_str,
                     :currency => socket.read_str,
                     :local_symbol => socket.read_str,
                     :contract_detail =>
                         IB::ContractDetail.new(
                             :market_name => socket.read_str,
                             :trading_class => socket.read_str)),
             :distance => socket.read_str,
             :benchmark => socket.read_str,
             :projection => socket.read_str,
             :legs => socket.read_str,
            }
          end
        end
      end # ScannerData

    end # module Incoming
  end # module Messages
end # module IB
