require 'spec_helper'

describe IB::Models::Order do

  let(:properties) do
    {:outside_rth => true,
     :open_close => 'C',
     :origin => IB::Models::Order::Origin_Firm,
     :transmit => false,
     :designated_location => "WHATEVER",
     :exempt_code => 123,
     :delta_neutral_order_type => "HACK",
     :what_if => true,
     :not_held => true}
  end

  context "instantiation" do
    context 'empty without properties' do
      subject { IB::Models::Order.new }

      it { should_not be_nil }
      its(:outside_rth) { should == false }
      its(:open_close) { should == "O" }
      its(:origin) { should == IB::Models::Order::Origin_Customer }
      its(:transmit) { should == true }
      its(:designated_location) { should == '' }
      its(:exempt_code) { should == -1 }
      its(:delta_neutral_order_type) { should == '' }
      its(:what_if) { should == false }
      its(:not_held) { should == false }
      its(:created_at) { should be_a Time }
    end

    context 'with properties' do
      subject { IB::Models::Order.new properties }

      it 'sets properties right' do
        properties.each do |name, value|
          subject.send(name).should == value
        end
      end

      context 'essential properties are still set, even if not given explicitely' do
        its(:created_at) { should be_a Time }
      end
    end

    it 'allows setting attributes' do
      x = IB::Models::Order.new
      expect {
        x.outside_rth = true
        x.open_close = 'C'
        x.origin = IB::Models::Order::Origin_Firm
        x.transmit = false
        x.designated_location = "WHATEVER"
        x.exempt_code = 123
        x.delta_neutral_order_type = "HACK"
        x.what_if = true
        x.not_held = true
      }.to_not raise_error

      x.outside_rth.should == true
      x.open_close.should == 'C'
      x.origin.should == IB::Models::Order::Origin_Firm
      x.transmit.should == false
      x.designated_location.should == "WHATEVER"
      x.exempt_code.should == 123
      x.delta_neutral_order_type.should == "HACK"
      x.what_if.should == true
      x.not_held.should == true
    end
  end #instantiation

  context 'equality' do
    subject { IB::Models::Order.new properties }

    it 'be self-equal ' do
      should == subject
    end

    it 'be equal to Order with the same properties' do
      should == IB::Models::Order.new(properties)
    end
  end

end # describe IB::Models::Order
