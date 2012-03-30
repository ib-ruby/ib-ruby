require 'spec_helper'

describe IB::Models::Execution do # AKA IB::Execution

  let(:properties) do
    {:account_name => "DU111110",
     :average_price => 1.31075,
     :client_id => 1111,
     :cumulative_quantity => 20000,
     :exchange => "IDEALPRO",
     :exec_id => "0001f4e8.4f5d48f1.01.01",
     :liquidation => 0,
     :order_id => 373,
     :perm_id => 1695693613,
     :price => 1.31075,
     :shares => 20000,
     :side => :buy,
     :time => "20120312  15:41:09"
    }
  end

  context "instantiation" do
    context 'empty without properties' do
      subject { IB::Execution.new }

      it { should_not be_nil }
      its(:order_id) { should == 0 }
      its(:client_id) { should == 0 }
      its(:perm_id) { should == 0 }
      its(:shares) { should == 0 }
      its(:price) { should == 0 }
      its(:liquidation) { should == 0 }
      its(:created_at) { should be_a Time }
    end

    context 'with properties' do
      subject { IB::Execution.new properties }

      it 'sets properties right' do
        properties.each do |name, value|
          subject.send(name).should == value
        end
      end
    end
  end #instantiation

  context "properties" do

    it 'allows setting properties' do
      expect {
        x = IB::Execution.new
        properties.each do |name, value|
          subject.send("#{name}=", value)
          subject.send(name).should == value
        end
      }.to_not raise_error
    end

    it 'sets side as directed by its setter' do
      @x = IB::Execution.new
      ['BOT', 'BUY', 'Buy', 'buy', :BUY, :BOT, :Buy, :buy, 'B', :b].each do |val|
        expect { @x.side = val }.to_not raise_error
        @x.side.should == :buy
      end

      ['SELL', 'SLD', 'Sel', 'sell', :SELL, :SLD, :Sell, :sell, 'S', :S].each do |val|
        expect { @x.side = val }.to_not raise_error
        @x.side.should == :sell
      end
    end
  end # properties

end # describe IB::Models::Contract
