require 'message_helper'
require 'account_helper'


shared_examples_for 'Connected Connection'  do

  subject { @ib }

  it_behaves_like 'Connected Connection without receiver'

  it 'keeps received messages in Hash by default' do
    expect(subject.received).to be_a Hash
  end

  it 'has received a :NextValidId' do
    expect(subject.received[:NextValidId]).not_to be_empty
  end

end

shared_examples_for 'Connected Connection without receiver' do

  it { should_not be_nil }
  it { should be_connected }
  its(:server_version) { should be_an Integer }
  its(:client_version) { should be_an Integer }
  its(:subscribers) { is_expected.not_to be_empty } # :NextValidId and empty Hashes 
  its(:next_local_id) { should be_an Integer } # Not before :NextValidId arrives
end

# Need top level method to access instance var (@received) in nested context
def create_connection opts={}
  # Start disconnected (we need to set up catch-all subscriber first)
  @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger).merge(opts)

  # Hash of received messages, keyed by message type
  @received = Hash.new { |hash, key| hash[key] = Array.new }

  @alert = @ib.subscribe(:Alert) { |msg| puts msg.to_human }

  @subscriber = proc { |msg| @received[msg.message_type] << msg }
end

describe IB::Connection, focus: true do

  context 'instantiated with default options' do #, :connected => true do
    before(:all) do
      ## Ability to inspect Connection#subscribers
      IB::Connection.send(:public, *IB::Connection.protected_instance_methods) 
      create_connection
      @ib.wait_for :NextValidId
    end

    after(:all) { close_connection }

    it_behaves_like 'Connected Connection'

    describe '#send_message', 'sending messages' do
      it 'allows 3 signatures representing IB::Messages::Outgoing' do
        expect { @ib.send_message :RequestOpenOrders }.to_not raise_error

        expect { @ib.send_message IB::Messages::Outgoing::RequestOpenOrders
        }.to_not raise_error

        expect { @ib.send_message IB::Messages::Outgoing::RequestOpenOrders.new
        }.to_not raise_error
      end

      it 'has legacy #dispatch alias' do
        expect { @ib.dispatch :RequestOpenOrders }.to_not raise_error
      end
    end

    context "subscriptions" do
      before(:all) do
        @id = {} # Moving id between contexts. Feels dirty.
      end

      describe '#subscribe', focus: true do
        after(:all) { clean_connection }

        it 'adds (multiple) subscribers, returning subscription id' do
          @id[:first] = @ib.subscribe(IB::Messages::Incoming::OrderStatus) do |msg|
            log msg.to_human
          end

          @id[:second] = @ib.subscribe /Value/, :OpenOrder, @subscriber

          @id[:third] = @ib.subscribe /Account/, &@subscriber

          [[@id[:first], IB::Messages::Incoming::OrderStatus],
           [@id[:second], IB::Messages::Incoming::OpenOrder],
           [@id[:second], IB::Messages::Incoming::PortfolioValue],
           [@id[:second], IB::Messages::Incoming::AccountValue], # as /Value/
           [@id[:third], IB::Messages::Incoming::AccountValue], #  as /Account/
           [@id[:third], IB::Messages::Incoming::AccountDownloadEnd],
           [@id[:third], IB::Messages::Incoming::AccountUpdateTime],
          ].each do |(subscriber_id, message_class)|
            expect(@ib.subscribers).to have_key(message_class)
            expect(@ib.subscribers[message_class]).to have_key(subscriber_id)
          end
        end

        it 'returns Integer subscription id' do
          expect(@id[:first]).to be_an Integer
          expect(@id[:second]).to be_an Integer
          expect(@id[:third]).to be_an Integer
        end

        context 'when subscribed' do

          before(:all) do
            @ib.send_message :RequestAccountData, subscribe: true , account_code: ACCOUNT
            @ib.wait_for :AccountDownloadEnd, 3
          end

          after(:all) { @ib.send_message :RequestAccountData, subscribe: false, account_code: ACCOUNT }

          it 'receives subscribed message types and processes them in subscriber callback' do
            print "Sad API Warning for new accounts PortfolioValue can be empty causing a series of spec errors."
					  expect(@ib.received.keys).to include(:AccountValue, :AccountUpdateTime, :PortfolioValue, :AccountDownloadEnd) 
            expect(@ib.received[:AccountValue]).not_to be_empty
            expect(@ib.received[:PortfolioValue]).not_to be_empty
            expect(@ib.received[:AccountDownloadEnd]).not_to be_empty
            expect(@ib.received[:AccountUpdateTime]).not_to be_empty
          end

          it_behaves_like 'Valid account data request'
        end
      end # subscribe

      describe '#unsubscribe'  do  # this fails if "describe "#subscribe" is not run before
				
				before(:all) { @result = @ib.unsubscribe @id[:first], @id[:second] }

        it 'removes all subscribers at given id or ids' do
          [IB::Messages::Incoming::OrderStatus,
           IB::Messages::Incoming::OpenOrder,
           IB::Messages::Incoming::PortfolioValue,
           IB::Messages::Incoming::AccountValue,
          ].each do |message_class|
            expect(@ib.subscribers[message_class]).not_to have_key(@id[:first])
            expect(@ib.subscribers[message_class]).not_to have_key(@id[:second])
          end
        end

        it 'does not remove subscribers at other ids' do
          expect(@ib.subscribers[IB::Messages::Incoming::AccountValue]).to have_key(@id[:third])
          expect(@ib.subscribers[IB::Messages::Incoming::AccountDownloadEnd]).to have_key(@id[:third])
          expect(@ib.subscribers[IB::Messages::Incoming::AccountUpdateTime]).to have_key(@id[:third])
        end

        it 'returns an Array of removed subscribers' do
          expect(@result).to be_an Array
          expect(@result.size).to eq(4)
        end

#        it 'raises on nosense id given' do   # down not raise error, insteed prints log entries
#          expect { @ib.unsubscribe 'nonsense' }.to raise_error /No subscribers with id/
#          expect { @ib.unsubscribe rand(9999999) }.to raise_error /No subscribers with id/
#        end
      end

      context 'when unsubscribed'  do

        before(:all) do
          @ib.send_message :RequestAccountData, subscribe: true , account_code: ACCOUNT
          @ib.wait_for { !@received[:AccountDownloadEnd].empty? }
        end

        after(:all) { @ib.send_message :RequestAccountData,  subscribe: false , account_code: ACCOUNT }

        it 'receives subscribed message types still subscribed' do
          expect(@received[:AccountValue]).not_to be_empty
          expect(@received[:AccountUpdateTime]).not_to be_empty
          expect(@received[:AccountDownloadEnd]).not_to be_empty
        end

        it 'does not receive unsubscribed message types' do
          expect(@received[:PortfolioValue]).to be_empty
        end

        # this orginally tested for a lack of subscriber for PortfolioValue message which does not see to exist
      #  it { log_entries.any? { |entry| expect(entry).to match(/No subscribers with id nonsense/) }}
#        it { log_entries.any? { |entry| expect(entry).to match(/No subscribers for message .*:Alert!/) }}
     #   it { log_entries.any? { |entry| expect(entry).not_to match(/No subscribers for message .*:AccountValue/) }}
      end # when subscribed
    end # subscriptions

    describe '#connect' do
      it 'raises on another connection attempt' do
        expect { @ib.connect }.to raise_error /Already connected/
      end
    end
  end # connected

	## the following tests fail
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

end # describe IB::Connection
