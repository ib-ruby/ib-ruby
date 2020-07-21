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
				using IBSupport  # extended Array-Class  from abstract_message

        def load
          super

          @results = Array.new(@data[:count]) do |_|
            {:rank => buffer.read_int,
             :contract =>
                 Contract.build(
                     :con_id => buffer.read_int,
                     :symbol => buffer.read_string,
                     :sec_type => buffer.read_string,
                     :expiry => buffer.read_string,
                     :strike => buffer.read_decimal,
                     :right => buffer.read_string,
                     :exchange => buffer.read_string,
                     :currency => buffer.read_string,
                     :local_symbol => buffer.read_string,
                     :contract_detail =>
                         IB::ContractDetail.new(
                             :market_name => buffer.read_string,
                             :trading_class => buffer.read_string)),
             :distance => buffer.read_string,
             :benchmark => buffer.read_string,
             :projection => buffer.read_string,
             :legs => buffer.read_string,
            }
          end
        end
      end # ScannerData

    end # module Incoming
  end # module Messages
end # module IB
