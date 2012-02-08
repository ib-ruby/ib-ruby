require 'message_helper'

describe IB::Messages do

  context 'when connected to IB Gateway', :connected => true do

    before(:all) do
      connect_and_receive(:NextValidID, :OpenOrderEnd, :Alert,
                          :TickPrice, :TickSize)
      wait_for 1
    end

    after(:all) { p @received; @ib.close if @ib }

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
        it { should be_warning }
        it { should_not be_error }
      end

      context "received :TickPrice message" do
        subject { @received[:TickPrice].first }

        it { should_not be_nil }
        its(:type) { should_not be_nil }
        its(:data) { should be_a Hash }
        its(:data) { should have_key(:id) }
      end

      context "received :TickSize message" do
        subject { @received[:TickSize].first }

        it { should_not be_nil }
        its(:type) { should_not be_nil }
        its(:data) { should be_a Hash }
        its(:data) { should have_key(:id) }
      end
    end # Subscription Market Data and receive Tick Price and Tick Size msg's
  end # connected
end # describe IB::Messages::Incomming
