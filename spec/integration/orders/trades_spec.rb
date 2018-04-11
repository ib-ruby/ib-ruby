require 'order_helper'



describe "Trades", :connected => true, :integration => true, :slow => true do

  before(:all) { verify_account;  IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)  }

  context "Trading Forex", :if => :forex_trading_hours do

    before(:all) do
      ib = IB::Connection.current
      ib.wait_for :NextValidId
			@initial_order_id =  ib.next_local_id
    end

    after(:all) { close_connection }


     let(:contract) { IB::Symbols::Forex[:eurusd] }   # referenced by shared examples
		 [ :buy, :sell ].each_with_index do | the_action, count |
    context "Placing #{the_action.to_s.upcase} order"  do

			let(:order) { IB::Market.order( size: 20000, action: the_action, account: ACCOUNT ) } # referenced by shared examples
      before(:all) do
				ib = IB::Connection.current
        @local_id_placed = place_the_order contract: IB::Symbols::Forex.eurusd do | price |
          @order=  IB::Market.order :size => 20000,				# order and contract cannot be uised on this level
																	  :action => the_action,
																		:account => ACCOUNT
				end

        #:what_if => true

        ib.wait_for(5, :ExecutionData, :OpenOrder) do
          ib.received[:OpenOrder].last && ib.received[:OpenOrder].last.order.commission
        end
      end

      after(:all) do
        clean_connection # Clear logs and message collector
   #     IB::Connection.current.cancel_order @local_id_placed # Just in case...
      end

			context IB::Connection  do
			subject{  IB::Connection.current  }
			its( :next_local_id ){ is_expected.to eq @initial_order_id +1 + count  }
      it { expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message }
      it { expect( subject.received[:OrderStatus]).to have_at_least(1).status_message }
      it { expect( subject.received[:ExecutionData]).to have_exactly(1).execution_data }
      it { expect( subject.received[:CommissionReport]).to have_exactly(1).report }

			end 



			context IB::Messages::Incoming::OpenOrder do
				subject{ IB::Connection.current.received[:OpenOrder].last }
				it_behaves_like 'OpenOrder message'
			end

			context IB::Order do
				subject{ IB::Connection.current.received[:OpenOrder].last.order }
#				it{ is_expected.to eql @order  }  uncomment to display the difference between the
				#																	order send to the tws and the response after filling
				it_behaves_like 'Placed Order'
				it_behaves_like 'Filled Order'
			end

			context IB::Messages::Incoming::ExecutionData do
				subject { IB::Connection.current.received[:ExecutionData].last }
				it_behaves_like 'Proper Execution Record' , the_action 
			end

			context IB::Messages::Incoming::CommissionReport do
				subject{ IB::Connection.current.received[:CommissionReport].last }
				it_behaves_like 'Valid CommissionReport' , count
			end

    end # Placing 
		 end # each

    context "Request executions" do
      # TODO: RequestExecutions with filters?

      before(:all) do
				ib =  IB::Connection.current
        @request_id = ib.send_message :RequestExecutions,
                         :client_id => OPTS[:connection][:client_id],
												  account: OPTS[:connection][:account],
                         :time => (Time.now.utc-10).to_ib # Time zone problems possible
        ib.wait_for :ExecutionData, 3 # sec
      end

      #after(:all) { clean_connection }

      it 'does not receive Order-related messages' do
				puts "time"
				puts  (Time.now.utc-10).to_ib
        expect( IB::Connection.current.received[:OpenOrder]).to be_empty
        expect( IB::Connection.current.received[:OrderStatus]).to be_empty
      end

      it 'receives ExecutionData messages' do
        expect( IB::Connection.current.received[:ExecutionData]).to have_at_least(1).execution_data
      end

     # it 'receives Execution Data' do
     #   execution_should_be :buy, :index => 0, :request_id => 456
     #   execution_should_be :sell, :request_id => 456
     # end

      it 'also receives Commission Reports' do
        expect( IB::Connection.current.received[:CommissionReport]).to have_exactly(2).reports

       # commission_report_should_be :no_pnl, @ib.received[:ExecutionData].first.execution
       # commission_report_should_be :with_pnl, @ib.received[:ExecutionData].last.execution
      end

    end # Request executions
  end # Forex order

end # Trades

__END__

Actual message exchange for "Request executions" (TWS 925):
10:57:41:348 <- 7-3-456-1111--20120430 10:57:31-----
10:57:41:349 -> 11-9-456-1-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbb0b.01.01-20120430  10:57:36-DU118180-IDEALPRO-BOT-20000-1.32540-474073463-1111-0-20000-1.32540--
10:57:41:350 -> 11-9-456-2-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbb0c.01.01-20120430  10:57:36-DU118180-IDEALPRO-SLD-20000-1.32540-474073464-1111-0-20000-1.32540--
10:57:41:350 -> 59-1-0001f4e8.4f9dbb0b.01.01-2.5-USD-1.7976931348623157E308-1.7976931348623157E308--
10:57:41:350 -> 59-1-0001f4e8.4f9dbb0c.01.01-2.5-USD-27.7984-1.7976931348623157E308--
10:57:41:351 -> 55-1-456-

Actual message exchange for "Request executions" (TWS 923):
11:11:45:436 <- 7-3-456-1111--20120430 11:11:36-----
11:11:45:439 -> 11-8-456-1-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbc96.01.01-20120430  11:11:43-DU118180-IDEALPRO-BOT-20000-1.32485-308397342-1111-0-20000-1.32485--
11:11:45:439 -> 11-8-456-2-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbc9a.01.01-20120430  11:11:45-DU118180-IDEALPRO-SLD-20000-1.32480-308397343-1111-0-20000-1.32480--
11:11:45:439 -> 55-1-456-
