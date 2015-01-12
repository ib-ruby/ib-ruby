### needs cleaning ####
require 'message_helper'
require 'account_helper'

shared_examples_for 'Connected Connection' do
  
  subject { connection }

 it_behaves_like 'Connected Connection without receiver'

  it 'keeps received messages in Hash by default' do
	  expect( connection.received).to be_a Hash
	  expect( connection.received[:Alert]).not_to be_empty
	  expect( connection.received[:Alert]).to have_at_least(1).message
	  ## The test for an Item in the  NextValidID-Hash fails surprisingly
	  expect( connection.received[:NextValidId]).not_to be_empty
	  expect( connection.received[:NextValidId]).to have_exactly(1).message
#	  connection.close
  end
end

shared_examples_for 'Connected Connection without receiver' do

  it { is_expected.not_to  be_nil }
  it { is_expected.to  be_connected }
  its(:reader) { is_expected.to be_a Thread }
  its(:server_version) { is_expected.to be_an Integer }
  its(:client_version) { is_expected.to  be_an Integer }
  its(:subscribers) { is_expected.to have_at_least(1).item } # :NextValidId and empty Hashes
  its(:next_local_id) { is_expected.to be_a Fixnum } # Not before :NextValidId arrives
end

# Need top level method to access instance var (@received) in nested context
def create_connection opts={}
  # Start disconnected (we need to set up catch-all subscriber first)
	puts OPTS[:connection].inspect
  @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger).merge(opts)

  # Hash of received messages, keyed by message type
#  @received = Hash.new { |hash, key| hash[key] = Array.new }

 # @subscriber = proc { |msg| @received[msg.message_type] << msg }
end

describe IB::Connection do

	context 'instantiated with default options', :connected => true  do
		before(:context) do
			@ib = IB::Connection.new OPTS[:connection].merge(client_id:1001,:logger => mock_logger, connect:false) #.merge(opts)
			@subscriber_id =  Hash.new
			@unsubscriber_id = nil
			@ib.connect
			@ib.wait_for :NextValidId
			#
		end

		#    after(:all) { @ib.close }

		it_behaves_like 'Connected Connection' do
			let( :connection ) { @ib }
		end

		describe '#send_message', 'sending messages'   do
			it 'allows 3 signatures representing IB::Messages::Outgoing'  do
				expect { @ib.send_message :RequestOpenOrders }.to_not raise_error

				expect { @ib.send_message IB::Messages::Outgoing::RequestOpenOrders }.to_not raise_error

				expect { @ib.send_message IB::Messages::Outgoing::RequestOpenOrders.new }.to_not raise_error
			end

			it 'has legacy #dispatch alias'do
				expect { @ib.dispatch :RequestOpenOrders }.to_not raise_error
			end
		end
		context "subscriptions" do
			#			let!( :subscriber_id ){ Hash.new  }

			describe '#subscribe' do
				#        after(:all) { clean_connection }
				let( :subscriber ) { Proc.new {} }
				#
				it 'adds (multiple) subscribers, returning subscription id' do
					@subscriber_id[:first] = @ib.subscribe(IB::Messages::Incoming::OrderStatus) do |msg|
						log msg.to_human
					end
					@subscriber_id[:second] = @ib.subscribe /Value/, :OpenOrder, subscriber

					@subscriber_id[:third] = @ib.subscribe /Account/, &subscriber

					[[ @subscriber_id[:first], IB::Messages::Incoming::OrderStatus ],
      [ @subscriber_id[ :second], IB::Messages::Incoming::OpenOrder  ],
      [ @subscriber_id[ :second], IB::Messages::Incoming::PortfolioValue ],
      [ @subscriber_id[ :second], IB::Messages::Incoming::AccountValue ], # as /Value/
      [ @subscriber_id[ :third ], IB::Messages::Incoming::AccountValue ], #  as /Account/
      [ @subscriber_id[ :third ], IB::Messages::Incoming::AccountDownloadEnd ],
      [ @subscriber_id[ :third ], IB::Messages::Incoming::AccountUpdateTime ],
					].each do |(subscriber_id, message_class)|
						expect( @ib.subscribers).to have_key(message_class)
						expect( @ib.subscribers[message_class]).to have_key(subscriber_id)
					end
					## subscriber_id's	
					@subscriber_id.values.each{ |v| expect(v).to be_an Integer }
					## initiate var for further usage
					@unsubscriber_id = @ib.unsubscribe @subscriber_id[:first], @subscriber_id[:second] 
					#				end # it
					#it 'returns an Array of removed subscribers' do
					expect( @unsubscriber_id).to be_an Array
					expect( @unsubscriber_id).to have_exactly(4).deleted_subscribers
				end
			end # describe
			context 'when subscribed' do

				before(:all) do
					## if the advisor-account is used here, the test fails because PortfolioValueData are missing
					@ib.send_message :RequestAccountData,  :account_code => OPTS[:connection][:user]
					@ib.wait_for :AccountDownloadEnd, 3
				end

				after(:all) { @ib.send_message :RequestAccountData, :subscribe => false }

				it 'receives subscribed message types and processes them in subscriber callback' do
					[:AccountValue, :PortfolioValue, :AccountDownloadEnd, :AccountUpdateTime].each do |x|
						expect( @ib.received[ x ] ).not_to be_empty
					end
				end

				it_behaves_like 'Valid account data request'
			end  # context 'when subscribed'
		end # describe #subscribe 
		#
		describe '#unsubscribe' do

			it 'removes all subscribers at given id or ids'  do
				[IB::Messages::Incoming::OrderStatus,
     IB::Messages::Incoming::OpenOrder,
     IB::Messages::Incoming::PortfolioValue,
     IB::Messages::Incoming::AccountValue,
				].each do |message_class|
				  [:first,:second].each do |key|
					expect( @ib.subscribers[message_class]).not_to have_key( @subscriber_id[ key ] )
					end
				end
			end

			it 'does not remove subscribers at other ids' do
							
				[IB::Messages::Incoming::AccountValue, 
												IB::Messages::Incoming::AccountDownloadEnd,
												IB::Messages::Incoming::AccountUpdateTime ].each do | msg| 
																expect( @ib.subscribers[msg]).to have_key(@subscriber_id[:third])
				end
			end

			#it 'returns an Array of removed subscribers' do  ---> moved to line 106
			#				@unsubscriber_id.should be_an Array
			#				@unsubscriber_id.should have_exactly(4).deleted_subscribers
			#end

			it 'raises on nosense id given' do
				expect { @ib.unsubscribe 'nonsense' }.to raise_error /No subscribers with id/
				expect { @ib.unsubscribe rand(9999999) }.to raise_error /No subscribers with id/
			end
		end

      context 'when unsubscribed' do

        before(:all) do
          @ib.send_message :RequestAccountData
          @ib.wait_for { !@ib.received[:AccountDownloadEnd].empty? }
        end

        after(:all) { @ib.send_message :RequestAccountData, :subscribe => false }

        it 'receives subscribed message types still subscribed' do
								[:AccountValue,	:AccountUpdateTime, :AccountDownloadEnd].each do  |sy|
												expect( @ib.received[sy]).not_to be_empty
								end
        end

#        it 'does not receive unsubscribed message types' do
#         @ib.received[:PortfolioValue].should be_empty
#       end

        it { should_log /No subscribers for message .*:PortfolioValue/ }
        it { should_not_log /No subscribers for message .*:AccountValue/ }
      end # when subscribed
    end # subscriptions

#    describe '#connect' do
#      it 'raises on another connection attempt' do
#        expect { @ib.connect }.to raise_error /Already connected/
#      end
#    end
#  end # connected
#
#  context 'instantiated passing :connect => false' do
#    before(:all) { create_connection :connect => false,
#                                     :reader => false }
#    subject { @ib }
#
#    it { should_not be_nil }
#    it { should_not be_connected }
#    its(:reader) { should be_nil }
#    its(:server_version) { should be_nil }
#    its(:client_version) { should be_nil }
#    its(:received) { should be_empty }
#    its(:subscribers) { should be_empty }
#    its(:next_local_id) { should be_nil }
#
#    describe 'connecting idle conection' do
#      before(:all) do
#        @ib.connect
#        @ib.start_reader
#        @ib.wait_for :NextValidId
#      end
#      after(:all) { close_connection }
#
#      it_behaves_like 'Connected Connection'
#    end
#
#  end # not connected
#
#  context 'instantiated passing :received => false' do
#    before(:all) { create_connection :connect => false,
#                                     :reader => false,
#                                     :received => false }
#    subject { @ib }
#
#    it { should_not be_nil }
#    it { should_not be_connected }
#    its(:reader) { should be_nil }
#    its(:server_version) { should be_nil }
#    its(:client_version) { should be_nil }
#    its(:received) { should be_empty }
#    its(:subscribers) { should be_empty }
#    its(:next_local_id) { should be_nil }
#
#    describe 'connecting idle conection' do
#      before(:all) do
#        @ib.connect
#        @ib.start_reader
#        @ib.wait_for 1 # ib.received not supposed to work!
#      end
#      after(:all) { close_connection }
#
#      it_behaves_like 'Connected Connection without receiver'
#    end
#
#  end # not connected
#
end # describe IB::Connection
