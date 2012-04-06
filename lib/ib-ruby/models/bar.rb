module IB
  module Models
    # This is a single data point delivered by HistoricData messages.
    # Instantiate with a Hash of attributes, to be auto-set via initialize in Model.
    class Bar < Model
      prop :time, # The date-time stamp of the start of the bar. The format is
           #        determined by the reqHistoricalData() formatDate parameter.
           :open, #   The bar opening price.
           :high, #   The high price during the time covered by the bar.
           :low, #    The low price during the time covered by the bar.
           :close, #  The bar closing price.
           :volume, # The bar opening price.
           :wap, #    Weighted average price during the time covered by the bar.
           :has_gaps, # Whether or not there are gaps in the data.
           :trades # int: When TRADES data history is returned, represents number
                   # of trades that occurred during the time period the bar covers

      def to_s
        "<Bar #{time}: wap: #{wap}, OHLC: #{open}, #{high}, #{low}, #{close}, " +
            (trades ? "trades: #{trades}," : "") + " vol: #{volume}, gaps? #{has_gaps}>"
      end
    end # class Bar
  end # module Models
end # module IB
