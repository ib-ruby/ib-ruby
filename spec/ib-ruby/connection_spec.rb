require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe IB::Connection do

  context 'when connected to IB Gateway', :connected => true do
    # THIS depends on TWS|Gateway connectivity
    before(:all) { @ib = IB::Connection.new }
    after(:all) { @ib.close if @ib }

    context 'instantiation with default options' do
      subject { @ib }

      it { should_not be_nil }
      it { should be_connected }
      its (:server) {should be_a Hash}
      its (:subscribers) {should have_at_least(1).item} # :NextValidID and empty Hashes
      its (:next_order_id) {should be_a Fixnum} # Not before :NextValidID arrives
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

       it '#subscribe, adds (multiple) subscribers' do
         @subscriber_id = @ib.subscribe(IB::Messages::Incoming::Alert, :AccountValue) do
           puts "oooooooooo"
         end

         @subscriber_id.should be_a Fixnum

         @ib.subscribers.should have_key(IB::Messages::Incoming::Alert)
         @ib.subscribers.should have_key(IB::Messages::Incoming::AccountValue)
         @ib.subscribers[IB::Messages::Incoming::Alert].should have_key(@subscriber_id)
         @ib.subscribers[IB::Messages::Incoming::AccountValue].should have_key(@subscriber_id)
         @ib.subscribers[IB::Messages::Incoming::Alert][@subscriber_id].should be_a Proc
         @ib.subscribers[IB::Messages::Incoming::AccountValue][@subscriber_id].should be_a Proc
       end

       it '#unsubscribe, removes all subscribers at this id' do
         @ib.unsubscribe(@subscriber_id)

         @ib.subscribers[IB::Messages::Incoming::Alert].should_not have_key(@subscriber_id)
         @ib.subscribers[IB::Messages::Incoming::AccountValue].should_not have_key(@subscriber_id)
       end

     end # subscriptions
  end # connected

  context 'not connected to IB Gateway' do
    before(:all) { @ib = IB::Connection.new :open => false }

    context 'instantiation passing :open => false' do
      subject { @ib }

      it { should_not be_nil }
      it { should_not be_connected }
      its (:server) {should be_a Hash}
      its (:subscribers) {should be_empty}
      its (:next_order_id) {should be_nil}
    end

  end # not connected
end # describe IB::Connection
