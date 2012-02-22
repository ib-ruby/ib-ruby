require 'spec_helper'

describe IB::Connection do

  context 'when connected to IB Gateway', :connected => true do
    # THIS depends on TWS|Gateway connectivity
    before(:all) do
      @ib = IB::Connection.new CONNECTION_OPTS
      @ib.subscribe(:OpenOrderEnd) {}
    end

    after(:all) { @ib.close if @ib }

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
        expect {
          @ib.send_message :RequestOpenOrders, :subscribe => true
        }.to_not raise_error

        expect {
          @ib.send_message IB::Messages::Outgoing::RequestOpenOrders, :subscribe => true
        }.to_not raise_error

        expect {
          @ib.send_message IB::Messages::Outgoing::RequestOpenOrders.new(:subscribe => true)
        }.to_not raise_error
      end

      it 'has legacy #dispatch alias' do
        expect { @ib.dispatch :RequestOpenOrders, :subscribe => true
        }.to_not raise_error
      end
    end

    context "subscriptions" do

      it '#subscribe, adds(multiple) subscribers' do
        @subscriber_id = @ib.subscribe(IB::Messages::Incoming::Alert, :OpenOrder, /Value/) do
        end

        @subscriber_id.should be_a Fixnum

        [IB::Messages::Incoming::Alert,
         IB::Messages::Incoming::OpenOrder,
         IB::Messages::Incoming::AccountValue,
         IB::Messages::Incoming::PortfolioValue
        ].each do |message_class|
          @ib.subscribers.should have_key(message_class)
          @ib.subscribers[message_class].should have_key(@subscriber_id)
        end
      end

      it '#unsubscribe, removes all subscribers at this id' do
        @ib.unsubscribe(@subscriber_id)

        [IB::Messages::Incoming::Alert,
         IB::Messages::Incoming::OpenOrder,
         IB::Messages::Incoming::AccountValue,
         IB::Messages::Incoming::PortfolioValue
        ].each do |message_class|
          @ib.subscribers[message_class].should_not have_key(@subscriber_id)
        end
      end

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
