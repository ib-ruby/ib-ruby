require 'message_helper'
require 'account_helper'

# Need top level method to access instance var (@received) in nested context
def connect_to_ib
  # Start disconnected (we need to set up catch-all subscriber first)
  @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

  @ib.subscribe(:OpenOrderEnd) {}

  # Hash of received messages, keyed by message type
  @received = Hash.new { |hash, key| hash[key] = Array.new }

  @subscriber = proc { |msg| @received[msg.message_type] << msg }
end


describe IB::Connection do

  context 'when connected to IB Gateway', :connected => true do
    # THIS depends on TWS|Gateway connectivity
    before(:all) { connect_to_ib }

    after(:all) { close_connection }

    context 'instantiation with default options' do
      subject { @ib }

      it { should_not be_nil }
      it { should be_connected }
      its(:server) { should be_a Hash }
      its(:server) { should have_key :reader }
      its(:subscribers) { should have_at_least(1).item } # :NextValidID and empty Hashes
      its(:next_order_id) { should be_a Fixnum } # Not before :NextValidID arrives
    end

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

      describe '#subscribe' do
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
            @ib.subscribers.should have_key(message_class)
            @ib.subscribers[message_class].should have_key(subscriber_id)
          end
        end

        it 'returns Integer subscription id' do
          @id[:first].should be_an Integer
          @id[:second].should be_an Integer
          @id[:third].should be_an Integer
        end

        context 'when subscribed' do

          before(:all) do
            @ib.send_message :RequestAccountData

            wait_for(5) { received? :AccountDownloadEnd }
          end

          after(:all) { @ib.send_message :RequestAccountData, :subscribe => false }

          it 'receives subscribed message types and processes them in subscriber callback' do
            @received[:AccountValue].should_not be_empty
            @received[:PortfolioValue].should_not be_empty
            @received[:AccountDownloadEnd].should_not be_empty
            @received[:AccountUpdateTime].should_not be_empty
          end

          it_behaves_like 'Valid account data request'
        end
      end

      describe '#unsubscribe' do
        before(:all) { @result = @ib.unsubscribe @id[:first], @id[:second] }

        it 'removes all subscribers at given id or ids' do
          [IB::Messages::Incoming::OrderStatus,
           IB::Messages::Incoming::OpenOrder,
           IB::Messages::Incoming::PortfolioValue,
           IB::Messages::Incoming::AccountValue,
          ].each do |message_class|
            @ib.subscribers[message_class].should_not have_key(@id[:first])
            @ib.subscribers[message_class].should_not have_key(@id[:second])
          end
        end

        it 'does not remove subscribers at other ids' do
          @ib.subscribers[IB::Messages::Incoming::AccountValue].should have_key(@id[:third])
          @ib.subscribers[IB::Messages::Incoming::AccountDownloadEnd].should have_key(@id[:third])
          @ib.subscribers[IB::Messages::Incoming::AccountUpdateTime].should have_key(@id[:third])
        end

        it 'returns an Array of removed subscribers' do
          @result.should be_an Array
          @result.should have_exactly(4).deleted_subscribers
        end

        it 'raises on nosense id given' do
          expect { @ib.unsubscribe 'nonsense' }.to raise_error /No subscribers with id/
          expect { @ib.unsubscribe rand(9999999) }.to raise_error /No subscribers with id/
        end
      end

      context 'when subscribed' do

        before(:all) do
          @ib.send_message :RequestAccountData

          wait_for(5) { received? :AccountDownloadEnd }
        end

        after(:all) { @ib.send_message :RequestAccountData, :subscribe => false }

        it 'receives subscribed message types still subscribed' do
          @received[:AccountValue].should_not be_empty
          @received[:AccountDownloadEnd].should_not be_empty
          @received[:AccountUpdateTime].should_not be_empty
        end

        it 'does not receive unsubscribed message types' do
          @received[:PortfolioValue].should be_empty
        end

      end # when subscribed
    end # subscriptions
  end # connected

  context 'when not connected to IB Gateway' do
    before(:all) { @ib = IB::Connection.new :connect => false, :reader => false }

    context 'instantiation passing :connect => false' do
      subject { @ib }

      it { should_not be_nil }
      it { should_not be_connected }
      its(:server) { should be_a Hash }
      its(:server) { should_not have_key :reader }
      its(:subscribers) { should be_empty }
      its(:next_order_id) { should be_nil }
    end

  end # not connected
end # describe IB::Connection
