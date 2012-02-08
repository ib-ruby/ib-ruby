require 'message_helper'

describe IB::Messages::Incoming do

  context 'when connected to IB Gateway', :connected => true do

    before(:all) do
      connect_and_receive(:Alert, :AccountValue,
                          :PortfolioValue, :AccountUpdateTime)
    end

    after(:all) { p @received; @ib.close if @ib }

    context "Subscribe to :AccountValue and receive appropriate msg's" do

      before(:all) do
        ##TODO consider a follow the sun market lookup for windening the types tested
        @ib.send_message :RequestAccountData, :subscribe => true
        wait_for(5) { @received[:AccountValue].size > 3 && @received[:PortfolioValue].size > 1 }
      end

      after(:all) { @ib.send_message :RequestAccountData, :subscribe => false }

      context "received :AccountValue message" do
        subject { @received[:AccountValue].first }

        it { should_not be_nil }
        its(:type) { should_not be_nil }
        its(:data) { should be_a Hash }
      end

      context "received :PortfolioValue message" do
        subject { @received[:PortfolioValue].first }

        it { should_not be_nil }
        its(:type) { should_not be_nil }
        its(:data) { should be_a Hash }
      end
    end # Subscribe to :AccountValue and receive appropriate msg's
  end # connected
end # describe IB::Messages::Incomming
