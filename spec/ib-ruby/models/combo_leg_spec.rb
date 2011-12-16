require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe IB::Models::ComboLeg do

  let(:properties) do
    {:con_id => 123,
     :ratio=> 1234,
     :action => 'BUY',
     :exchange => 'BLAH',
     :open_close => IB::Models::ComboLeg::OPEN,
     :short_sale_slot => 1,
     :designated_location => 'BLEH',
     :exempt_code => 12}
  end

  context "instantiation" do
    context 'empty without properties' do
      subject { IB::Models::ComboLeg.new }

      it { should_not be_nil }
      its (:con_id) {should == 0}
      its (:ratio) {should == 0}
      its (:open_close) {should == 0}
      its (:short_sale_slot) {should == 0}
      its (:exempt_code) {should == -1}

      its (:created_at) {should be_a Time}
    end

    context 'with properties' do
      subject { IB::Models::ComboLeg.new properties }

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
        x = IB::Models::ComboLeg.new
        properties.each do |name, value|
          subject.send("#{name}=", value)
          subject.send(name).should == value
        end
      }.to_not raise_error
    end
  end #instantiation

end # describe IB::Models::Contract::ComboLeg
