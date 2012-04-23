require 'order_helper'

shared_examples_for 'OpenOrder message' do
  it { should be_an IB::Messages::Incoming::OpenOrder }
  its(:message_type) { should == :OpenOrder }
  its(:message_id) { should == 5 }
  its(:version) { should == 28 }
  its(:data) { should_not be_empty }
  its(:local_id) { should be_an Integer }
  its(:status) { should =~ /Submit/ }
  its(:to_human) { should =~
      /<OpenOrder: <Contract: WFC stock NYSE USD> <Order: LMT DAY buy 100 .*Submit.* 9.13 #\d+\/\d+ from 1111/ }

  it 'has proper contract accessor' do
    c = subject.contract
    c.should be_an IB::Contract
    c.symbol.should == 'WFC'
    c.exchange.should == 'NYSE'
  end

  it 'has proper order accessor' do
    o = subject.order
    o.should be_an IB::Order
    o.client_id.should == 1111
    o.parent_id.should == 0
    o.local_id.should be_an Integer
    o.perm_id.should be_an Integer
    o.order_type.should == :limit
    o.tif.should == :day
    o.status.should =~ /Submit/
  end

  it 'has proper order_state accessor' do
    os = subject.order_state
    os.local_id.should be_an Integer
    os.perm_id.should be_an Integer
    os.client_id.should == 1111
    os.parent_id.should == 0
    os.status.should =~ /Submit/
  end

  it 'has class accessors as well' do
    subject.class.message_id.should == 5
    subject.class.version.should == [23, 28] # Two message versions supported
    subject.class.message_type.should == :OpenOrder
  end

end

describe IB::Messages::Incoming::OpenOrder do

  context 'Instantiated with data Hash' do
    subject do
      IB::Messages::Incoming::OpenOrder.new :version => 28,
                                            :order =>
                                                {:local_id => 1313,
                                                 :perm_id => 172323928,
                                                 :client_id => 1111,
                                                 :parent_id => 0,
                                                 :side => :buy,
                                                 :order_type => :limit,
                                                 :limit_price => 9.13,
                                                 :total_quantity => 100,
                                                },
                                            :order_state =>
                                                {:local_id => 1313,
                                                 :perm_id => 172323928,
                                                 :client_id => 1111,
                                                 :parent_id => 0,
                                                 :status => 'PreSubmitted',
                                                },
                                            :contract =>
                                                {:symbol => 'WFC',
                                                 :exchange => 'NYSE',
                                                 :currency => 'USD',
                                                 :sec_type => :stock
                                                }
    end

    it_behaves_like 'OpenOrder message'
  end

  context 'received from IB' do
    before(:all) do
      verify_account
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId
      place_order IB::Symbols::Stocks[:wfc]
      @ib.wait_for :OpenOrder
    end

    after(:all) { close_connection } # implicitly cancels order

    subject { @ib.received[:OpenOrder].first }

    it_behaves_like 'OpenOrder message'

    #it 'has extended order_state attributes' do
  end
end # describe IB::Messages:Incoming
