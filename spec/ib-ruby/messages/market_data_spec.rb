require 'message_helper'

describe IB::Messages do

  context 'Request Market Data', :connected => true do

    context 'when subscribed to :Tick... messages' do

      before(:all) do
        connect_and_receive :Alert, :TickPrice, :TickSize

        ##TODO consider a follow the sun market lookup for windening the types tested
        @ib.send_message :RequestMarketData, :id => 456,
                         :contract => IB::Symbols::Forex[:eurusd]
        wait_for(5) { @received[:TickPrice].size > 3 && @received[:TickSize].size > 1 }
      end

      after(:all) do
        @ib.send_message :CancelMarketData, :id => 456
        close_connection
      end

      context "received :Alert message " do
        subject { @received[:Alert].first }

        it 'ouoe' do
          p subject
          p subject.to_human
        end

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
        its(:type) { should be_a Symbol }
        its(:price) { should be_a Float }
        its(:size) { should be_an Integer }
        its(:data) { should be_a Hash }
        its(:id) { should == 456 } # ticker_id
        its(:to_human) { should =~ /TickPrice/ }
      end

      context "received :TickSize message" do
        subject { @received[:TickSize].first }

        it { should_not be_nil }
        its(:type) { should_not be_nil }
        its(:data) { should be_a Hash }
        its(:tick_type) { should be_an Integer }
        its(:type) { should be_a Symbol }
        its(:size) { should be_an Integer }
        its(:id) { should == 456 }
        its(:to_human) { should =~ /TickSize/ }
      end
    end # when subscribed to :Tick... messages

    context 'when NOT subscribed to :Tick... messages' do

      before(:all) do
        connect_and_receive :NextValidID

        @ib.send_message :RequestMarketData, :id => 456,
                         :contract => IB::Symbols::Forex[:eurusd]
        wait_for(2)
      end

      after(:all) do
        @ib.send_message :CancelMarketData, :id => 456
        close_connection
      end

      it "logs warning about unhandled :OpenOrderEnd message" do
        should_log /No subscribers for message IB::Messages::Incoming::OpenOrderEnd/
      end

      it "logs warning about unhandled :Alert message" do
        should_log /No subscribers for message IB::Messages::Incoming::Alert/
      end

      it "logs warning about unhandled :Tick... messages" do
        should_log /No subscribers for message IB::Messages::Incoming::TickPrice/,
                   /No subscribers for message IB::Messages::Incoming::TickSize/
      end

    end # NOT subscribed to :Tick... messages

  end # Request Market Data
end # describe IB::Messages
