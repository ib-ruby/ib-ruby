require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe IB::Connection do

  context "new" do
    context 'connected by default' do
      # THIS depends on TWS|Gateway connectivity
      before(:all) { @ib = IB::Connection.new }
      after(:all) { @ib.close }
      subject { @ib }

      it { should_not be_nil }
      it { should be_connected }
      its (:server) {should be_a Hash}
      its (:subscribers) {should have_at_least(1).listener} # :NextValidID and empty Hashes
      its (:next_order_id) {should be_a Fixnum} # Not before :NextValidID arrives
    end

    context 'passing :open => false' do
      subject { IB::Connection.new :open => false }

      it { should_not be_nil }
      it { should_not be_connected }
      its (:server) {should be_a Hash}
      its (:subscribers) {should be_empty}
      its (:next_order_id) {should be_nil}
    end
  end #instantiation

  context "subscriptions" do
    # THIS depends on TWS|Gateway connectivity
    before(:all) { @ib = IB::Connection.new }
    after(:all) { @ib.close }

    it 'adds (multiple) subscribers' do
      @subscriber_id = @ib.subscribe(:Alert, :AccountValue) do
        puts "oooooooooo"
      end

      @ib.subscribers.should have_key(IB::Messages::Incoming::Alert)
      @ib.subscribers.should have_key(IB::Messages::Incoming::AccountValue)
      @ib.subscribers[IB::Messages::Incoming::Alert].should have_key(@subscriber_id)
      @ib.subscribers[IB::Messages::Incoming::AccountValue].should have_key(@subscriber_id)
      @ib.subscribers[IB::Messages::Incoming::Alert][@subscriber_id].should be_a Proc
      @ib.subscribers[IB::Messages::Incoming::AccountValue][@subscriber_id].should be_a Proc
    end

    it 'removes all subscribers' do
      @subscriber_id = @ib.unsubscribe(@subscriber_id)

      @ib.subscribers[IB::Messages::Incoming::Alert].should_not have_key(@subscriber_id)
      @ib.subscribers[IB::Messages::Incoming::AccountValue].should_not have_key(@subscriber_id)
    end

  end #subscriptions
end # describe IB::Connection
