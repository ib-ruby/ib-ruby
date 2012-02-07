require 'spec_helper'
require 'thread'

describe IB::Messages::Incoming do

  context 'when connected to IB Gateway', :connected => true do

    context "Subscribe to Market Data and check Tick Price and Tick Size msg's" do

        @count =  Queue.new
        @ib = IB::Connection.new
        @subscriber_alert = @ib.subscribe(:Alert, :AccountValue) do |msg|
          puts msg.to_human
          context "message on Alert" do
            subject { msg }
            it { should be_warning }
            it { should_not be_error }
          end
        end

        @subscriber_tick_price = @ib.subscribe(:TickPrice) do |msg|
          @count << msg

          context "message on tick price" do
            subject { msg }

            it { should_not be_nil }
            its(:type) {should_not be_nil}
            its(:data) {should be_a Hash}
            its(:data) {should have_key(:id)}

          end
        end

        @subscriber_tick_size = @ib.subscribe(:TickSize) do |msg|
          context "message on tick size" do
            subject { msg }

            it { should_not be_nil }
            its(:type) {should_not be_nil}
            its(:data) {should be_a Hash}
            its(:data) {should have_key(:id)}

          end
        end

        #TODO consider a follow the sun market lookup for windening the types tested
        @ib.send_message :RequestMarketData, :id => 456, :contract => IB::Symbols::Forex[:eurusd]

        #Wait for 3 tick prices events or 30 seconds
        breaker = 0
        until @count.size > 3 || breaker > 30 do
          sleep 1
          breaker += 1
        end

        @ib.close if @ib

    end # Subscription Market Data and receive Tick Price and Tick Size msg's

    context "Subscribe to Market Data and error on receive Tick Price and Tick Size msg's" do

        RSpec::Mocks::setup(self) # did not figure out how to do this just for logger

        @count =  Queue.new
        @ib = IB::Connection.new
        @subscriber_alert = @ib.subscribe(:Alert, :AccountValue) do |msg|
          @count << msg
          puts msg.to_human
          context "message on Alert" do

            subject { msg }
            it { should be_warning }
            it { should_not be_error }
           end
        end

        log.should_receive(:warn).with("No subscribers for message #{IB::Messages::Incoming::OpenOrderEnd}!").at_least(:once)
        log.should_receive(:warn).with("No subscribers for message #{IB::Messages::Incoming::TickPrice}!").at_least(:once)
        log.should_receive(:warn).with("No subscribers for message #{IB::Messages::Incoming::TickSize}!").at_least(:once)
        #puts "\n\object.methods : "+ log.methods.sort.join("\n").to_s+"\n\n"

        @ib.send_message :RequestMarketData, :id => 456, :contract => IB::Symbols::Forex[:eurusd]

        #Wait for 3 tick prices events or 30 seconds
        #TODO Think about a stub implementation of log.warn to emit counts.
        breaker = 0
        until @count.size > 3 || breaker > 30 do
          sleep 1
          breaker += 1
        end

        @ib.close if @ib

    end # Subscription Market Data and receive Tick Price and Tick Size msg's
  end # connected
end # describe IB::Messages::Incomming
