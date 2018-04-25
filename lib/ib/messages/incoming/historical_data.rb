module IB
  module Messages
    module Incoming

      # HistoricalData contains following @data:
			#
      # _General_:
			#
      # - request_id - The ID of the request to which this is responding
      # - count - Number of Historical data points returned (size of :results).
      # - results - an Array of Historical Data Bars
      # - start_date - beginning of returned Historical data period
      # - end_date   - end of returned Historical data period
      # 
			# Each returned Bar in @data[:results] Array contains this data:
      # - date - The date-time stamp of the start of the bar. The format is
      #   determined by the RequestHistoricalData formatDate parameter.
      # - open -  The bar opening price.
      # - high -  The high price during the time covered by the bar.
      # - low -   The low price during the time covered by the bar.
      # - close - The bar closing price.
      # - volume - The volume during the time covered by the bar.
      # - trades - When TRADES historical data is returned, represents number of trades
      #   that occurred during the time period the bar covers
      # - wap - The weighted average price during the time covered by the bar.
      # - has_gaps - Whether or not there are gaps in the data.

      HistoricalData = def_message [17, 3],
                                   [:request_id, :int],
                                   [:start_date, :string],
                                   [:end_date, :string],
                                   [:count, :int]
      class HistoricalData
        attr_accessor :results
				using IBSupport  # extended Array-Class  from abstract_message
 
        def load
          super

          @results = Array.new(@data[:count]) do |_|
            IB::Bar.new :time => buffer.read_string,
                        :open => buffer.read_decimal,
                        :high => buffer.read_decimal,
                        :low => buffer.read_decimal,
                        :close => buffer.read_decimal,
                        :volume => buffer.read_int,
                        :wap => buffer.read_decimal,   # python: average
#                        :has_gaps => buffer.read_string,  # python only if serverVersion < MIN_SERVER_VER_SYNT_REALTIME_BARS
                        :trades => buffer.read_int   # python:  BarCount
          end
        end

        def to_human
          "<HistoricalData: #{request_id}, #{count} items, #{start_date} to #{end_date}>"
        end
      end # HistoricalData
=begin
				 ## python code
			# def processHistogramData(self,fields):
        sMsgId = next(fields)
        reqId = decode(int, fields)
        numPoints = decode(int, fields)

        histogram = []
        for idxBar in range(numPoints):
            dataPoint = HistogramData()
            dataPoint.price = decode(float,fields)
            dataPoint.count = decode(int,fields)
            histogram.append(dataPoint)
=end


				HistogramData  = def_message( [89,0], 
																		 [:strange_version_item, :int], 
																	[:request_id, :int], 
																	[ :number_of_points , :int ]) do
																		# to human
          "<HistogramData: #{request_id}, #{number_of_points} read>"
																	end

      class HistogramData
        attr_accessor :results
				using IBSupport  # extended Array-Class  from abstract_message
 
        def load
          super

          @results = Array.new(@data[:number_of_points]) do |_|
						{ price:  buffer.read_decimal, 
						 count: buffer.read_int }
					end
				end
			end

    end # module Incoming
  end # module Messages
end # module IB
