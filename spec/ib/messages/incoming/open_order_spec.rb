require 'order_helper'

shared_examples_for 'OpenOrder message' do
  it { should be_an IB::Messages::Incoming::OpenOrder }
  its(:message_type) { should == :OpenOrder }
  its(:message_id) { should == 5 }
  its(:version) { should == 30}
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
    subject.class.version.should == 30 # Message versions supported
    subject.class.message_type.should == :OpenOrder
  end

end

describe IB::Messages::Incoming::OpenOrder do

  context 'Instantiated with data Hash' do
    subject do
      IB::Messages::Incoming::OpenOrder.new :version => 30,
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
      @ib.wait_for :OpenOrder, 3
      @ib.received?(:OpenOrder).should be_true
    end

    after(:all) { close_connection } # implicitly cancels order

    subject { @ib.received[:OpenOrder].first }

    it_behaves_like 'OpenOrder message'

    #it 'has extended order_state attributes' do
  end
end # describe IB::Messages:Incoming

__END__
11:55:04:543 <- 3-38-22 -0-USD -BAG--0.0---SMART--USD----BUY-1 -MKT------O-0--1-0-0-0-0-0-0-0-2-101360836-1-SELL-SMART-0-0---1-81032967-1-BUY-SMART-0-0---1-0-0--0.0-------0---1-0---0---0-0--0------0-----0--------0---0-0--0-
12:20:02:859 <- 3-38-22 -0-GOOG-BAG--0.0---SMART--USD----BUY-10-LMT-0.01-   -   ---O-0-Original-1-0-0-0-0-0-0-0-2-101360836-1-SELL-SMART-0-0---1-81032967-1-BUY-SMART-0-0---1-0-0--0.0-------0---1-0---0---0-0--0------0-----0--------0---0-0--0-
11:58:07:100 <- 3-38-304-0-GOOG-BAG--0.0---SMART--USD----BUY-10-LMT-0.01-0.0-DAY---O-0-Original-1-0-0-0-0-0-0-0-3-81032967-1-BUY-SMART-0-0---1-81032968-2-SELL-SMART-0-0---1-81032973-1-BUY-SMART-0-0---1-3----0--0.0-------0---1-0---0---0-0--0------0-----0--------0---0-0--0-

22:34:23:993 <- 3-38-17- 0-WFC-STK--0.0---NYSE--USD----BUY-100-LMT-9.13-0.0-DAY---O-0--1-0-0-0-0-0-0-0--0.0-------0---1-0---0---0-0--0------0-----0--------0---0-0--1-
22:34:25:203 <- 3-38-18 -0-WFC-STK--0.0---NYSE--USD----BUY-100-LMT-9.13-0.0-DAY---O-0--1-0-0-0-0-0-0-0--0.0-------0---1-0---0---0-0--0------0-----0--------0---0-0--0-
00:11:37:820 <- 3-38-180-0-WFC-STK--0.0---NYSE--USD----BUY-100-LMT-9.13-   -   ---O-0--1-0-0-0-0-0-0-0--0.0-------0---1-0---0---0-0--0------0-----0--------0---0-0--0-

