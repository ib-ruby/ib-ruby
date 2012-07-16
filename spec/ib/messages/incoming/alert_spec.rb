require 'message_helper'

shared_examples_for 'Alert message' do
  it { should be_an IB::Messages::Incoming::Alert }
  it { should be_warning }
  it { should_not be_error }
  its(:message_type) { should == :Alert }
  its(:message_id) { should == 4 }
  its(:version) { should == 2 }
  its(:data) { should_not be_empty }
  its(:error_id) { should == -1 }
  its(:code) { should == 2104 }
  its(:message) { should =~ /Market data farm connection is OK/ }
  its(:to_human) { should =~ /TWS Warning/ }

  it 'has class accessors as well' do
    subject.class.message_id.should == 4
    subject.class.message_type.should == :Alert
  end
end

describe IB::Messages::Incoming do

  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Incoming::Alert.new(
          :version => 2,
          :error_id => -1,
          :code => 2104,
          :message => 'Market data farm connection is OK:cashfarm')
    end

    it_behaves_like 'Alert message'
  end

  context 'Message received from IB', :connected => true do

    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :Alert
      pending 'No Alert received upon connect!' unless @ib.received? :Alert
    end

    after(:all) { close_connection }

    subject { @ib.received[:Alert].first }

    it_behaves_like 'Alert message'
  end #
end # describe IB::Messages:Incoming
