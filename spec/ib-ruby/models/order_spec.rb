require 'spec_helper'

describe IB::Models::Order do

  let(:properties) do
    {:outside_rth => true,
     :open_close => 'C',
     :origin => IB::Order::Origin_Firm,
     :transmit => false,
     :designated_location => "WHATEVER",
     :exempt_code => 123,
     :delta_neutral_order_type => "HACK",
     :what_if => true,
     :not_held => true}
  end

  context "instantiation" do
    context 'empty without properties' do
      subject { IB::Order.new }

      it { should_not be_nil }
      its(:outside_rth) { should == false }
      its(:open_close) { should == "O" }
      its(:origin) { should == IB::Order::Origin_Customer }
      its(:transmit) { should == true }
      its(:designated_location) { should == '' }
      its(:exempt_code) { should == -1 }
      its(:delta_neutral_order_type) { should == '' }
      its(:what_if) { should == false }
      its(:not_held) { should == false }
      its(:created_at) { should be_a Time }
    end

    context 'with properties' do
      subject { IB::Order.new properties }

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
      x = IB::Order.new
      properties.each do |name, value|
        subject.send("#{name}=", value)
        subject.send(name).should == value
      end
    end
  end #instantiation

  context 'equality' do
    subject { IB::Order.new properties }

    it 'is  self-equal ' do
      should == subject
    end

    it 'is equal to Order with the same properties' do
      should == IB::Order.new(properties)
    end

    it 'is not equal for Orders with different limit price' do
      order1 = IB::Order.new :total_quantity => 100,
                                     :limit_price => 1,
                                     :action => 'BUY'

      order2 = IB::Order.new :total_quantity => 100,
                                     :limit_price => 2,
                                     :action => 'BUY'
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different total_quantity' do
      order1 = IB::Order.new :total_quantity => 20000,
                                     :limit_price => 1,
                                     :action => 'BUY'

      order2 = IB::Order.new :total_quantity => 100,
                                     :action => 'BUY',
                                     :limit_price => 1
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different action/side' do
      order1 = IB::Order.new :total_quantity => 100,
                                     :limit_price => 1,
                                     :action => 'SELL'

      order2 = IB::Order.new :total_quantity => 100,
                                     :action => 'BUY',
                                     :limit_price => 1
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different order_type' do
      order1 = IB::Order.new :total_quantity => 100,
                                     :limit_price => 1,
                                     :action => 'BUY',
                                     :order_type => 'LMT'

      order2 = IB::Order.new :total_quantity => 100,
                                     :action => 'BUY',
                                     :limit_price => 1,
                                     :order_type => 'MKT'
      order1.should_not == order2
      order2.should_not == order1
    end
  end

end # describe IB::Order
