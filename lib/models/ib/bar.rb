module IB
  # This is a single data point delivered by HistoricData or RealTimeBar messages.
  # Instantiate with a Hash of attributes, to be auto-set via initialize in Model.
  class Bar < IB::Model
    include BaseProperties

    has_one :contract # The bar represents timeseries info for this Contract

    prop :open, #   The bar opening price.
      :high, #   The high price during the time covered by the bar.
      :low, #    The low price during the time covered by the bar.
      :close, #  The bar closing price.
      :volume, # Volume
      :wap, #    Weighted average price during the time covered by the bar.
      :trades, # int: When TRADES data history is returned, represents number
      #           of trades that occurred during the time period the bar covers
      :time #DateTime
      #        The date-time stamp of the start of the bar. The format is
      #        determined by the reqHistoricalData() formatDate parameter.
#      :has_gaps => :bool # Whether or not there are gaps in the data.  ## omitted since ServerVersion 124

      validates_numericality_of :open, :high, :low, :close, :volume

   def to_human
      "<Bar: #{time} wap #{wap} OHLC #{open} #{high} #{low} #{close} " +
        (trades ? "trades #{trades}" : "") + " vol #{volume}>"
    end

    alias to_s to_human
  end # class Bar
end # module IB
