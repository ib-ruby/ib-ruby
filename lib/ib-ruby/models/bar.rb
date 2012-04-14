module IB
  module Models
    # This is a single data point delivered by HistoricData or RealTimeBar messages.
    # Instantiate with a Hash of attributes, to be auto-set via initialize in Model.
    class Bar < Model.for(:bar)
      include ModelProperties

      prop :open, #   The bar opening price.
           :high, #   The high price during the time covered by the bar.
           :low, #    The low price during the time covered by the bar.
           :close, #  The bar closing price.
           :volume, # Volume
           :wap, #    Weighted average price during the time covered by the bar.
           :trades, # int: When TRADES data history is returned, represents number
           #           of trades that occurred during the time period the bar covers
           :time, # TODO: convert into Time object?
           #        The date-time stamp of the start of the bar. The format is
           #        determined by the reqHistoricalData() formatDate parameter.
           :has_gaps => :bool # Whether or not there are gaps in the data.

      validates_numericality_of :open, :high, :low, :close, :volume

      # Order comparison
      def == other
        time == other.time &&
            open == other.open &&
            high == other.high &&
            low == other.low &&
            close == other.close &&
            wap == other.wap &&
            trades == other.trades &&
            volume == other.volume
      end

      def to_human
        "<Bar: #{time} wap #{wap} OHLC #{open} #{high} #{low} #{close} " +
            (trades ? "trades #{trades}" : "") + " vol #{volume} gaps #{has_gaps}>"
      end

      alias to_s to_human
    end # class Bar
  end # module Models
end # module IB
