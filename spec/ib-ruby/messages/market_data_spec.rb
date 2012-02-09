require 'message_helper'

describe IB::Messages do

  # Pattern for writing message specs is like this:
  #
  # 1. You indicate your interest in some message types by calling 'connect_and_receive'
  #    in a top-level before(:all) block. All messages of given types will be caught
  #    and placed into @received Hash, keyed by message type
  #
  # 2. You send request messages to IB and then wait for specific conditions (or timeout)
  #    by calling 'wait_for' in a context before(:all) block.
  #
  # 3. Once the condition is satisfied, you can test the content of @received Hash
  #    to see what messages were received, or @log Array to see what was logged
  #
  # 4. When done, you disconnect @ib Connection in a top-level  after(:all) block.

  context 'when connected to IB Gateway', :connected => true do

    before(:all) do
      connect_and_receive(:NextValidID, :OpenOrderEnd, :Alert,
                          :TickPrice, :TickSize)
    end

    after(:all) { @ib.close if @ib
    p @received.map {|type, msg| [type, msg.size]}}

    it 'receives :NextValidID message' do
      @received[:NextValidID].should_not be_empty
    end

    it 'receives :OpenOrderEnd message' do
      @received[:OpenOrderEnd].should_not be_empty
    end

    context "Subscribe to Market Data and check Tick Price and Tick Size msg's" do

      before(:all) do
        ##TODO consider a follow the sun market lookup for windening the types tested
        @ib.send_message :RequestMarketData, :id => 456,
                         :contract => IB::Symbols::Forex[:eurusd]
        wait_for(5) { @received[:TickPrice].size > 3 && @received[:TickPrice].size > 1 }
      end

      after(:all) {  @ib.send_message :CancelMarketData, :id => 456 }

      context "received :Alert message " do
        subject { @received[:Alert].first }

        it { should_not be_nil }
        it { should be_warning }
        it { should_not be_error }
        its(:code) { should be_an Integer }
        its(:message) { should =~ /Market data farm connection is OK/ }
        its(:to_human) { should =~ /TWS Warning Message/ }
      end

      context "received :TickPrice message" do
        subject { @received[:TickPrice].first }

        it 'ouoe' do
          p subject
          p subject.to_human
        end

        it { should_not be_nil }
        its(:tick_type) { should be_an Integer }
        its(:type) { should be_a Symbol}
        its(:price) { should be_a Float}
        its(:size) { should be_an Integer}
        its(:data) { should be_a Hash }
        its(:id) { should == 456 }          # ticker_id
        its(:to_human) { should =~ /TickPrice/ }
      end

      context "received :TickSize message" do
        subject { @received[:TickSize].first }

        it { should_not be_nil }
        its(:type) { should_not be_nil }
        its(:data) { should be_a Hash }
        its(:tick_type) { should be_an Integer }
        its(:type) { should be_a Symbol}
        its(:size) { should be_an Integer}
        its(:id) { should == 456 }
        its(:to_human) { should =~ /TickSize/ }
      end
    end # Subscription Market Data and receive Tick Price and Tick Size msg's
  end # connected
end # describe IB::Messages::Incomming
