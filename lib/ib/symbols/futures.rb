# The Futures module tries to guess the front month future using a crude algorithm that
# does not take into account expiry/rollover day. This will be valid most of the time,
# but near/after expiry day the next quarter's contract takes over as the volume leader.

module IB
  module Symbols
    module Futures
      extend Symbols

      # Find the next front month of quarterly futures.
      # N.B. This will not work as expected during the front month before expiration, as
      # it will point to the next quarter even though the current month is still valid!
      def self.next_quarter_month time=Time.now
        [3, 6, 9, 12].find { |month| month > time.month } || 3 # for December, next March
      end

      def self.next_quarter_year time=Time.now
        next_quarter_month(time) < time.month ? time.year + 1 : time.year
      end

      # WARNING: This is currently broken. It returns the next
      # quarterly expiration month after the current month. Many futures
      # instruments have monthly contracts for the near months. This
      # method will not work for such contracts; it will return the next
      # quarter after the current month, even though the present month
      # has the majority of the trading volume.
      #
      # For example, in early November of 2011, many contracts have the
      # vast majority of their volume in the Nov 2011 contract, but this
      # method will return the Dec 2011 contract instead.
      #
      def self.next_expiry time=Time.now
        "#{ next_quarter_year(time) }#{ sprintf("%02d", next_quarter_month(time)) }"
      end

      # Convenience method; generates an IB::Future instance for a futures
      # contract with the given parameters.
      #
      # If expiry is nil, it will use the end month of the current
      # quarter. This will be wrong for most contracts most of the time,
      # since most contracts have the majority of their volume in a
      # nearby intraquarter month.
      #
      # It is recommended that you specify an expiration date manually
      # until next_expiry is fixed. Expiry should be a string in the
      # format "YYYYMM", where YYYY is the 4 digit year and MM is the 2
      # digit month. For example, November 2011 is "201111".
      #
      def self.future(base_symbol, exchange, currency, description="", expiry=nil)
        IB::Future.new :symbol => base_symbol,
          :expiry => expiry || next_expiry,
          :exchange => exchange,
          :currency => currency,
          :sec_type => SECURITY_TYPES[:future],
          :description => description
      end

      def self.contracts
	@contracts.presence ||( super.merge  :ym => IB::Future.new(:symbol => "YM",
                                  :expiry => next_expiry,
                                  :exchange => "ECBOT",
                                  :currency => "USD",
                                  :description => "Mini-DJIA future"),
         :nq => IB::Future.new(:symbol => "NQ",
                                  :expiry => next_expiry,
                                  :exchange => "GLOBEX",
                                  :currency => "USD",
                                  :multiplier => 20,
                                  :description => "E-Mini Nasdaq 100 future"),
         :es => IB::Future.new(:symbol => "ES",
                                  :expiry => next_expiry,
                                  :exchange => "GLOBEX",
                                  :currency => "USD",
                                  :multiplier => 50,
                                  :description => "E-Mini S&P 500 future"),
			:zn => IB::Future.new( symbol: 'ZN',
														expiry: next_expiry,
													  currency: 'USD',
													  multiplier: 1000,
													  exchange: 'ECBOT',
														description: 'US Treasury Note -- 10 Years'),
			:zb => IB::Future.new( symbol: 'ZB',
														expiry: next_expiry,
													  currency: 'USD',
													  multiplier: 1000,
													  exchange: 'ECBOT',
														description: 'US Treasury Note -- 30 Years'),
				:mini_dax => IB::Future.new( symbol: 'DAX', exchange: 'DTB', 
																	expiry:  next_expiry,
																	currency: 'EUR',
																	multiplier: 5,
																	description: 'Mini DAX-Future'),
			#	:dax => IB::Future.new( symbol: 'DAX', exchange: 'DTB', 
			#														expiry:  next_expiry,
			#														currency: 'EUR',
			#														multiplier: 25,
		#															description: 'DAX-Future'),
				:stoxx=> IB::Future.new( symbol: 'ESTX50', exchange: 'DTB', 
																	expiry:  next_expiry,
																	currency: 'EUR',
																	multiplier: 10,
																	description: 'EuroStoxx 50 -Future'),
        :gbp => IB::Future.new(:symbol => "GBP",
                                 :expiry => next_expiry,
                                 :exchange => "GLOBEX",
                                 :currency => "USD",
                                 :multiplier => 62500,
                                 :description => "British Pounds future"),
         :eur => IB::Future.new(:symbol => "EUR",
                                  :expiry => next_expiry,
                                  :exchange => "GLOBEX",
                                  :currency => "USD",
                                  :multiplier => 12500,
                                  :description => "Euro FX future"),
         :jpy => IB::Future.new(:symbol => "JPY",
                                  :expiry => next_expiry,
                                  :exchange => "GLOBEX",
                                  :currency => "USD",
                                  :multiplier => 12500000,
                                  :description => "Japanese Yen future"),
         :hsi => IB::Future.new(:symbol => "HSI",
                                  :expiry => next_expiry,
                                  :exchange => "HKFE",
                                  :currency => "HKD",
                                  :multiplier => 50,
                                  :description => "Hang Seng Index future"),
         :vix => IB::Future.new(:symbol => "VIX",
                                  :expiry => next_expiry,
                                  :exchange => "CFE", #"ECBOT",
                                  :currency => "USD",
                                  :description => "CBOE Volatility Index future"))
	
        
      end
    end
  end
end
