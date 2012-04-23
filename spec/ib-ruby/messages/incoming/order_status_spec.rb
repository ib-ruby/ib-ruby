require 'order_helper'

shared_examples_for 'OrderStatus message' do
  it { should be_an IB::Messages::Incoming::OrderStatus }
  its(:message_type) { should == :OrderStatus }
  its(:message_id) { should == 3 }
  its(:version) { should == 6 }
  its(:data) { should_not be_empty }
  its(:local_id) { should be_an Integer }
  its(:status) { should =~ /Submit/ }
  its(:to_human) { should =~
      /<OrderStatus: <OrderState: .*Submit.* #\d+\/\d+ from 1111 filled 0\/100/ }

  it 'has proper order_state accessor' do
    os = subject.order_state
    os.local_id.should be_an Integer
    os.perm_id.should be_an Integer
    os.client_id.should == 1111
    os.parent_id.should == 0
    os.filled.should == 0
    os.remaining.should == 100
    os.average_fill_price.should == 0.0
    os.last_fill_price.should == 0.0
    os.status.should =~ /Submit/
    os.why_held.should =~ /child|/
  end

  it 'has class accessors as well' do
    subject.class.message_id.should == 3
    subject.class.version.should == 6
    subject.class.message_type.should == :OrderStatus
  end

end

describe IB::Messages::Incoming::OrderStatus do

  context 'Instantiated with data Hash' do
    subject do
      IB::Messages::Incoming::OrderStatus.new :version => 6,
                                              :order_state =>
                                                  {:local_id => 1313,
                                                   :perm_id => 172323928,
                                                   :client_id => 1111,
                                                   :parent_id => 0,
                                                   :status => 'PreSubmitted',
                                                   :filled => 0,
                                                   :remaining => 100,
                                                   :average_fill_price => 0.0,
                                                   :last_fill_price => 0.0,
                                                   :why_held => 'child'}
    end

    it_behaves_like 'OrderStatus message'
  end

  context 'received from IB' do
    before(:all) do
      verify_account
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId
      clean_connection
      place_order IB::Symbols::Stocks[:wfc]
      @ib.wait_for :OrderStatus, 6
    end

    after(:all) { close_connection } # implicitly cancels order

    subject { @ib.received[:OrderStatus].first }

    it_behaves_like 'OrderStatus message'
  end

end # describe IB::Messages:Incoming
