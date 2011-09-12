require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe IB::Models::ContractDetails do

  let(:properties) do
    {:under_con_id => 123,
     :min_tick=> 1234,
     :callable => true,
     :puttable => true,
     :coupon => 12345,
     :convertible => true,
     :next_option_partial => true}
  end

  context "instantiation" do
    context 'empty without properties' do
      subject { IB::Models::ContractDetails.new }

      it { should_not be_nil }
      its (:summary) {should be_an IB::Models::Contract}
      its (:under_con_id) {should == 0}
      its (:min_tick) {should == 0}
      its (:callable) {should == false}
      its (:puttable) {should == false}
      its (:coupon) {should == 0}
      its (:convertible) {should == false}
      its (:next_option_partial) {should == false}

      its (:created_at) {should be_a Time}
    end

    context 'with properties' do
      subject { IB::Models::ContractDetails.new properties }

      it 'sets properties right' do
        properties.each do |name, value|
          subject.send(name).should == value
        end
      end

      context 'essential properties are still set, even if not given explicitely' do
        its (:created_at) {should be_a Time}
      end
    end

    it 'allows setting attributes' do
      expect {
        x = IB::Models::ContractDetails.new
        x.callable = true
        x.puttable = true
        x.convertible = true
        x.under_con_id = 321
        x.min_tick = 123
        x.next_option_partial = true
      }.to_not raise_error
    end
  end #instantiation

end # describe IB::Models::ContractDetails
