require 'message_helper'

describe IB::Messages::Outgoing  do

  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Outgoing::RequestAccountData.new(
        :subscribe => true,
      :account_code => 'DUH')
    end

    it { should be_an IB::Messages::Outgoing::RequestAccountData }
    its(:message_type) { should == :RequestAccountData }
    its(:message_id) { should == 6 }
    its(:data) { should == {:subscribe=>true, :account_code=>"DUH"}}
    its(:subscribe) { should == true }
    its(:account_code) { should == 'DUH' }
    its(:to_human) { should =~ /RequestAccountData/ }

    it 'has class accessors as well' do
      subject.class.message_type.should == :RequestAccountData
      subject.class.message_id.should == 6
      subject.class.version.should == 2
    end

    it 'encodes into Array' do
      subject.encode.should == [[6, 2], [], [true, "DUH"]]
    end

    it 'that is flattened before sending it over socket to IB server' do
      subject.preprocess.should == [6, 2, 1, "DUH"]
    end

    it 'and has correct #to_s representation' do
      subject.to_s.should == "6-2-1-DUH"
    end

  end
end # describe IB::Messages:Outgoing
