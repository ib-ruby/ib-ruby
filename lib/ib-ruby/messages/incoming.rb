# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode

module IB
  module Messages

    # Incoming IB messages
    module Incoming
      Classes = Array.new

      #
      # This is just a basic generic message from the server.
      #
      # Class variables:
      # @message_id - integer message id.
      #
      # Instance attributes:
      # @data - Hash of actual data read from a stream.
      #
      # Override the load(socket) method in your subclass to do actual reading into @data.
      #
      class AbstractMessage
        attr_accessor :created_at, :data

        def self.message_id
          @message_id
        end

        def initialize(socket, server_version)
          raise Exception.new("Don't use AbstractMessage directly; use the subclass for your specific message type") if self.class.name == "AbstractMessage"
          @created_at = Time.now
          @data = Hash.new
          @socket = socket
          @server_version = server_version

          self.load()

          @socket = nil

          #logger.debug(" * New #{self.class.name}: #{ self.to_human }")
        end

        def AbstractMessage.inherited(by)
          super(by)
          Classes.push(by)
        end

        def load
          raise Exception.new("Don't use AbstractMessage; override load() in a subclass.")
        end

        protected

        #
        # Load @data from the socket according to the given map.
        #
        # map is a series of Arrays in the format [ [ :name, :type ] ], e.g. autoload([:version, :int ], [:ticker_id, :int])
        # type identifiers must have a corresponding read_type method on socket (read_int, etc.).
        #
        def autoload(*map)
          ##logger.debug("autoloading map: " + map.inspect)
          map.each { |spec|
            @data[spec[0]] = @socket.__send__(("read_" + spec[1].to_s).to_sym)
          }
        end
      end # class AbstractMessage


      ### Actual message classes

      # The IB code seems to dispatch up to two wrapped objects for this message, a tickPrice
      # and sometimes a tickSize, which seems to be identical to the TICK_SIZE object.
      #
      # Important note from
      # http://chuckcaplan.com/twsapi/index.php/void%20tickPrice%28%29 :
      #
      # "The low you get is NOT the low for the day as you'd expect it
      # to be. It appears IB calculates the low based on all
      # transactions after 4pm the previous day. The most inaccurate
      # results occur when the stock moves up in the 4-6pm aftermarket
      # on the previous day and then gaps open upward in the
      # morning. The low you receive from TWS can be easily be several
      # points different from the actual 9:30am-4pm low for the day in
      # cases like this. If you require a correct traded low for the
      # day, you can't get it from the TWS API. One possible source to
      # help build the right data would be to compare against what Yahoo
      # lists on finance.yahoo.com/q?s=ticker under the "Day's Range"
      # statistics (be careful here, because Yahoo will use anti-Denial
      # of Service techniques to hang your connection if you try to
      # request too many bytes in a short period of time from them). For
      # most purposes, a good enough approach would start by replacing
      # the TWS low for the day with Yahoo's day low when you first
      # start watching a stock ticker; let's call this time T. Then,
      # update your internal low if the bid or ask tick you receive is
      # lower than that for the remainder of the day. You should check
      # against Yahoo again at time T+20min to handle the occasional
      # case where the stock set a new low for the day in between
      # T-20min (the real time your original quote was from, taking into
      # account the delay) and time T. After that you should have a
      # correct enough low for the rest of the day as long as you keep
      # updating based on the bid/ask. It could still get slightly off
      # in a case where a short transaction setting a new low appears in
      # between ticks of data that TWS sends you.  The high is probably
      # distorted in the same way the low is, which would throw your
      # results off if the stock traded after-hours and gapped down. It
      # should be corrected in a similar way as described above if this
      # is important to you."
      #
      class TickPrice < AbstractMessage
        @message_id = 1

        # TODO: rewrite
        def load
          autoload([:version, :int],
                   [:ticker_id, :int],
                   [:tick_type, :int],
                   [:price, :decimal],
                   [:size, :int],
                   [:can_auto_execute, :int])

          # the IB code translates these into 0, 3, and 5, respectively, and wraps them in a TICK_SIZE-type wrapper.
          #int sizeTickType = -1 ; // not a tick
          # switch (tickType) {
          #     case 1: // BID
          #         sizeTickType = 0 ; // BID_SIZE
          #         break ;
          #     case 2: // ASK
          #         sizeTickType = 3 ; // ASK_SIZE
          #         break ;
          #     case 4: // LAST
          #         sizeTickType = 5 ; // LAST_SIZE
          #         break ;
          # }
          # if (sizeTickType != -1) {
          #     eWrapper().tickSize( tickerId, sizeTickType, size);
          @data[:type] = case @data[:tick_type]
                           when 1
                             :bid
                           when 2
                             :ask
                           when 4
                             :last
                           when 6
                             :high
                           when 7
                             :low
                           when 9
                             :close
                           else
                             nil
                         end
          # IB then emits at most 2 events on eWrapper:
          #          tickPrice( tickerId, tickType, price, canAutoExecute)
          #          tickSize( tickerId, sizeTickType, size)

        end

        def inspect
          "Tick (" + @data[:type].to_s('F') + " at " + @data[:price].to_s('F') + ") " + super.inspect
        end

        def to_human
          @data[:size].to_s + " " + @data[:type].to_s + " at " + @data[:price].to_s('F')
        end

      end # TickPrice

      class TickSize < AbstractMessage
        @message_id = 2

        def load
          autoload([:version, :int],
                   [:ticker_id, :int],
                   [:tick_type, :int],
                   [:size, :int])

          @data[:type] = case @data[:tick_type]
                           when 0
                             :bid
                           when 3
                             :ask
                           when 5
                             :last
                           when 8
                             :volume
                           else
                             nil
                         end
        end

        def to_human
          @data[:type].to_s + " size: " + @data[:size].to_s
        end
      end # TickSize

      class OrderStatus < AbstractMessage
        @message_id = 3

        def load
          autoload [:version, :int],
                   [:id, :int],
                   [:status, :string],
                   [:filled, :int],
                   [:remaining, :int],
                   [:average_fill_price, :decimal],
                   [:perm_id, :int],
                   [:parent_id, :int],
                   [:last_fill_price, :decimal],
                   [:client_id, :int]
        end
      end

      class Error < AbstractMessage
        @message_id = 4

        def code
          @data && @data[:code]
        end

        def load
          autoload([:version, :int],
                   [:id, :int],
                   [:code, :int],
                   [:message, :string])
        end
      end

      def to_human
        "TWS #{@data[:code]}: #{@data[:message]}"
      end
    end # class ErrorMessage
    ErrorMessage = Error

    class OpenOrder < AbstractMessage
      @message_id = 5

      attr_accessor :order, :contract

      def load
        @order = Models::Order.new
        @contract = Models::Contract.new

        autoload([:version, :int])

        @order.id = @socket.read_int

        @contract.symbol = @socket.read_string
        @contract.sec_type = @socket.read_string
        @contract.expiry = @socket.read_string
        @contract.strike = @socket.read_decimal
        @contract.right = @socket.read_string
        @contract.exchange = @socket.read_string
        @contract.currency = @socket.read_string
        @contract.local_symbol = @socket.read_string

        @order.action = @socket.read_string
        @order.total_quantity = @socket.read_int
        @order.order_type = @socket.read_string
        @order.limit_price = @socket.read_decimal
        @order.aux_price = @socket.read_decimal
        @order.tif = @socket.read_string
        @order.oca_group = @socket.read_string
        @order.account = @socket.read_string
        @order.open_close = @socket.read_string
        @order.origin = @socket.read_int
        @order.order_ref = @socket.read_string
        @order.client_id = @socket.read_int
        @order.perm_id = @socket.read_int
        @order.outside_rth = (@socket.read_int == 1)
        @order.hidden = (@socket.read_int == 1)
        @order.discretionary_amount = @socket.read_decimal
        @order.good_after_time = @socket.read_string
        @socket.read_string # skip deprecated sharesAllocation field

        @order.fa_group = @socket.read_string
        @order.fa_method = @socket.read_string
        @order.fa_percentage = @socket.read_string
        @order.fa_profile = @socket.read_string
        @order.good_till_date = @socket.read_string
        @order.rule_80A = @socket.read_string
        @order.percent_offset = @socket.read_decimal
        @order.settling_firm = @socket.read_string
        @order.short_sale_slot = @socket.read_int
        @order.designated_location = @socket.read_string
        @order.exempt_code = @socket.read_int # skipped in ver 51?
        @order.auction_strategy = @socket.read_int
        @order.starting_price = @socket.read_decimal
        @order.stock_ref_price = @socket.read_decimal
        @order.delta = @socket.read_decimal
        @order.stock_range_lower = @socket.read_decimal
        @order.stock_range_upper = @socket.read_decimal
        @order.display_size = @socket.read_int
                            #@order.rth_only = @socket.read_boolean
        @order.block_order = @socket.read_boolean
        @order.sweep_to_fill = @socket.read_boolean
        @order.all_or_none = @socket.read_boolean
        @order.min_quantity = @socket.read_int
        @order.oca_type = @socket.read_int
        @order.etrade_only = @socket.read_boolean
        @order.firm_quote_only = @socket.read_boolean
        @order.nbbo_price_cap = @socket.read_decimal
        @order.parent_id = @socket.read_int
        @order.trigger_method = @socket.read_int
        @order.volatility = @socket.read_decimal
        @order.volatility_type = @socket.read_int
        @order.delta_neutral_order_type = @socket.read_string
        @order.delta_neutral_aux_price = @socket.read_decimal

        @order.continuous_update = @socket.read_int
        @order.reference_price_type = @socket.read_int
        @order.trail_stop_price = @socket.read_decimal
        @order.basis_points = @socket.read_decimal
        @order.basis_points_type = @socket.read_int
        @order.combo_legs_description = @socket.read_string
        @order.scale_init_level_size = @socket.read_int_max
        @order.scale_subs_level_size = @socket.read_int_max
        @order.scale_price_increment = @socket.read_decimal_max
        @order.clearing_account = @socket.read_string
        @order.clearing_intent = @socket.read_string
        @order.not_held = (@socket.read_int == 1)

        under_comp_present = (@socket.read_int == 1)

        if under_comp_present
          under_comp = Models::Contract::UnderComp.new
          under_comp.con_id = @socket.read_int
          under_comp.delta = @socket.read_decimal
          under_comp.price = @socket.read_decimal
          @contract.under_comp = under_comp
        end

        @order.algo_strategy = @socket.read_string

        unless @order.algo_strategy.nil? || @order.algo_strategy.empty?
          algo_params_count = @socket.read_int
          if algo_params_count > 0
            @order.algo_params = Hash.new
            algo_params_count.times do
              tag = @socket.read_string
              value = @socket.read_string
              @order.algo_params[tag] = value
            end
          end
        end
      end
    end # OpenOrder

    class AccountValue < AbstractMessage
      @message_id = 6

      def load
        autoload([:version, :int], [:key, :string], [:value, :string], [:currency, :string])
        version_load(2, [:account_name, :string])
      end

      def to_human
        "<AccountValue: acct ##{@data[:account_name]}; #{@data[:key]}=#{@data[:value]} (#{@data[:currency]})>"
      end

    end # AccountValue

    class PortfolioValue < AbstractMessage
      attr_accessor :contract

      @message_id = 7

      def load
        @contract = Models::Contract.new

        autoload([:version, :int])
        @contract.symbol = @socket.read_string
        @contract.sec_type = @socket.read_string
        @contract.expiry = @socket.read_string
        @contract.strike = @socket.read_decimal
        @contract.right = @socket.read_string
        @contract.currency = @socket.read_string
        @contract.local_symbol = @socket.read_string if @data[:version] >= 2

        autoload([:position, :int], [:market_price, :decimal], [:market_value, :decimal])
        version_load(3, [:average_cost, :decimal], [:unrealized_pnl, :decimal], [:realized_pnl, :decimal])
        version_load(4, [:account_name, :string])
      end

      def to_human
        "<PortfolioValue: update for #{@contract.to_human}: market price #{@data[:market_price].to_s('F')}; market value " +
            "#{@data[:market_value].to_s('F')}; position #{@data[:position]}; unrealized PnL #{@data[:unrealized_pnl].to_s('F')}; " +
            "realized PnL #{@data[:realized_pnl].to_s('F')}; account #{@data[:account_name]}>"
      end

    end # PortfolioValue

    class AccountUpdateTime < AbstractMessage
      @message_id = 8

      def load
        autoload([:version, :int], [:time_stamp, :string])
      end
    end # AccountUpdateTime


    #
    # This message is always sent by TWS automatically at connect.
    # The IB class subscribes to it automatically and stores the order id in
    # its :next_order_id attribute.
    class NextValidID < AbstractMessage
      @message_id = 9

      def load
        autoload([:version, :int], [:order_id, :int])
      end
    end # NextValidIDMessage

    class ContractData < AbstractMessage
      @message_id = 10

      attr_accessor :contract_details

      def load
        @contract_details = Models::Contract::Details.new

        autoload([:version, :int])

        @contract_details.summary.symbol = @socket.read_string
        @contract_details.summary.sec_type = @socket.read_string
        @contract_details.summary.expiry = @socket.read_string
        @contract_details.summary.strike = @socket.read_decimal
        @contract_details.summary.right = @socket.read_string
        @contract_details.summary.exchange = @socket.read_string
        @contract_details.summary.currency = @socket.read_string
        @contract_details.summary.local_symbol = @socket.read_string

        @contract_details.market_name = @socket.read_string
        @contract_details.trading_class = @socket.read_string
        @contract_details.con_id = @socket.read_int
        @contract_details.min_tick = @socket.read_decimal
        @contract_details.multiplier = @socket.read_string
        @contract_details.order_types = @socket.read_string
        @contract_details.valid_exchanges = @socket.read_string
        @contract_details.price_magnifier = @socket.read_int
      end
    end # ContractData


    class ExecutionData < AbstractMessage
      @message_id = 11
      attr_accessor :contract, :execution

      def load
        @contract = Models::Contract.new
        @execution = Models::Execution.new

        autoload([:version, :int], [:order_id, :int])

        @contract.symbol = @socket.read_string
        @contract.sec_type = @socket.read_string
        @contract.expiry = @socket.read_string
        @contract.strike = @socket.read_decimal
        @contract.right = @socket.read_string
        @contract.currency = @socket.read_string
        @contract.local_symbol = @socket.read_string if @data[:version] >= 2

        @execution.order_id = @data[:order_id]
        @execution.exec_id = @socket.read_string
        @execution.time = @socket.read_string
        @execution.account_number = @socket.read_string
        @execution.exchange = @socket.read_string
        @execution.side = @socket.read_string
        @execution.shares = @socket.read_int
        @execution.price = @socket.read_decimal

        @execution.perm_id = @socket.read_int if @data[:version] >= 2
        @execution.client_id = @socket.read_int if @data[:version] >= 3
        @execution.liquidation = @socket.read_int if @data[:version] >= 4
      end
    end # ExecutionData

    class MarketDepth < AbstractMessage
      @message_id = 12

      def load
        autoload([:version, :int], [:id, :int], [:position, :int], [:operation, :int], [:side, :int], [:price, :decimal], [:size, :int])
      end

    end # MarketDepth

    class MarketDepthL2 < AbstractMessage
      @message_id = 13

      def load
        autoload([:version, :int], [:id, :int], [:position, :int], [:market_maker, :string], [:operation, :int], [:side, :int],
                 [:price, :decimal], [:size, :int])
      end
    end # MarketDepthL2


    class NewsBulletins < AbstractMessage
      @message_id = 14

      def load
        autoload([:version, :int], [:news_message_id, :int], [:news_message_type, :int], [:news_message, :string], [:originating_exchange, :string])
      end

    end # NewsBulletins

    class ManagedAccounts < AbstractMessage
      @message_id = 15

      def load
        autoload([:version, :int], [:accounts_list, :string])
      end

    end # ManagedAccounts

    class ReceiveFa < AbstractMessage
      @message_id = 16

      def load
        autoload([:version, :int], [:fa_data_type, :int], [:xml, :string])
      end
    end # ReceiveFa

    class HistoricalData < AbstractMessage
      @message_id = 17

      def load
        autoload([:version, :int], [:req_id, :int])
        version_load(2, [:start_date_str, :string], [:end_date_str, :string])
        @data[:completed_indicator] = "finished-" + @data[:start_date_str] + "-" + @data[:end_date_str] if @data[:version] >= 2

        autoload([:item_count, :int])
        @data[:history] = Array.new(@data[:item_count]) { |index|
          attrs = {
              :date => @socket.read_string,
              :open => @socket.read_decimal,
              :high => @socket.read_decimal,
              :low => @socket.read_decimal,
              :close => @socket.read_decimal,
              :volume => @socket.read_int,
              :wap => @socket.read_decimal,
              :has_gaps => @socket.read_string
          }

          Models::Bar.new(attrs)
        }

      end

      def to_human
        "<HistoricalData: req id #{@data[:req_id]}, #{@data[:item_count]} items, from #{@data[:start_date_str]} to #{@data[:end_date_str]}>"
      end
    end # HistoricalData

    class BondContractData < AbstractMessage
      @message_id = 18
      attr_accessor :contract_details

      def load
        @contract_details = Models::Contract::Details.new
        @contract_details.summary.symbol = @socket.read_string
        @contract_details.summary.sec_type = @socket.read_string
        @contract_details.summary.cusip = @socket.read_string
        @contract_details.summary.coupon = @socket.read_decimal
        @contract_details.summary.maturity = @socket.read_string
        @contract_details.summary.issue_date = @socket.read_string
        @contract_details.summary.ratings = @socket.read_string
        @contract_details.summary.bond_type = @socket.read_string
        @contract_details.summary.coupon_type = @socket.read_string
        @contract_details.summary.convertible = @socket.read_boolean
        @contract_details.summary.callable = @socket.read_boolean
        @contract_details.summary.puttable = @socket.read_boolean
        @contract_details.summary.desc_append = @socket.read_string
        @contract_details.summary.exchange = @socket.read_string
        @contract_details.summary.currency = @socket.read_string
        @contract_details.market_name = @socket.read_string
        @contract_details.trading_class = @socket.read_string
        @contract_details.con_id = @socket.read_int
        @contract_details.min_tick = @socket.read_decimal
        @contract_details.order_types = @socket.read_string
        @contract_details.valid_exchanges = @socket.read_string
      end
    end # BondContractData

    class ScannerParameters < AbstractMessage
      @message_id = 19

      def load
        autoload([:version, :int], [:xml, :string])
      end
    end # ScannerParamters


    class ScannerData < AbstractMessage
      @message_id = 20

      attr_accessor :contract_details

      def load
        autoload([:version, :int], [:ticker_id, :int], [:number_of_elements, :int])
        @data[:results] = Array.new(@data[:number_of_elements]) { |index|
          {
              :rank => @socket.read_int
              ## TODO: Pick up here.
          }
        }

      end
    end # ScannerData

    Table = Hash.new
    Classes.each { |msg_class|
      Table[msg_class.message_id] = msg_class
    }

#logger.debug("Incoming message class table is #{Table.inspect}")

  end # module Incoming
end # module Messages

IncomingMessages = Messages::Incoming # Legacy alias

end # module IB

__END__

    // incoming msg id's
    static final int TICK_PRICE		= 1;
    static final int TICK_SIZE		= 2;
    static final int ORDER_STATUS	= 3;
    static final int ERR_MSG		= 4;
    static final int OPEN_ORDER         = 5;
    static final int ACCT_VALUE         = 6;
    static final int PORTFOLIO_VALUE    = 7;
    static final int ACCT_UPDATE_TIME   = 8;
    static final int NEXT_VALID_ID      = 9;
    static final int CONTRACT_DATA      = 10;
    static final int EXECUTION_DATA     = 11;
    static final int MARKET_DEPTH     	= 12;
    static final int MARKET_DEPTH_L2    = 13;
    static final int NEWS_BULLETINS    	= 14;
    static final int MANAGED_ACCTS    	= 15;
    static final int RECEIVE_FA    	    = 16;
    static final int HISTORICAL_DATA    = 17;
    static final int BOND_CONTRACT_DATA = 18;
    static final int SCANNER_PARAMETERS = 19;
    static final int SCANNER_DATA       = 20;
    static final int TICK_OPTION_COMPUTATION = 21;
    static final int TICK_GENERIC = 45;
    static final int TICK_STRING = 46;
    static final int TICK_EFP = 47;
    static final int CURRENT_TIME = 49;
    static final int REAL_TIME_BARS = 50;
    static final int FUNDAMENTAL_DATA = 51;
    static final int CONTRACT_DATA_END = 52;
    static final int OPEN_ORDER_END = 53;
    static final int ACCT_DOWNLOAD_END = 54;
    static final int EXECUTION_DATA_END = 55;
    static final int DELTA_NEUTRAL_VALIDATION = 56;
    static final int TICK_SNAPSHOT_END = 57;
