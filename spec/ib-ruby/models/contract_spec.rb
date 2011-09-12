require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe IB::Models::Contract do

  let(:properties) do
    {:symbol => "TEST",
     :sec_type => IB::Models::Contract::SECURITY_TYPES[:stock],
     :expiry => '200609',
     :strike => 1234,
     :right => "put",
     :multiplier => 123,
     :exchange => "SMART",
     :currency => "USD",
     :local_symbol => "baz"}
  end

  context "instantiation" do
    context 'empty without properties' do
      subject { IB::Models::Contract.new }

      it { should_not be_nil }
      its (:con_id) {should == 0}
      its (:strike) {should == 0}
      its (:sec_type) {should == ''}
      its (:created_at) {should be_a Time}
      its (:include_expired) {should == false}
    end

    context 'with properties' do
      subject { IB::Models::Contract.new properties }

      it 'sets properties right' do
        properties.each do |name, value|
          subject.send(name).should == value
        end
      end

      context 'essential properties are still set, even if not given explicitely' do
        its (:con_id) {should == 0}
        its (:created_at) {should be_a Time}
        its (:include_expired) {should == false}
      end
    end

    it 'allows setting attributes' do
      expect {
        x = IB::Models::Contract.new
        x.symbol = "TEST"
        x.sec_type = IB::Models::Contract::SECURITY_TYPES[:stock]
        x.expiry = 200609
        x.strike = 1234
        x.right = "put"
        x.multiplier = 123
        x.exchange = "SMART"
        x.currency = "USD"
        x.local_symbol = "baz"
      }.to_not raise_error
    end

    it 'raises on wrong security type' do
      expect {
        x = IB::Models::Contract.new({:sec_type => "asdf"})
      }.to raise_error ArgumentError

      expect {
        x = IB::Models::Contract.new
        x.sec_type = "asdf"
      }.to raise_error ArgumentError
    end

    it 'accepts pre-determined security types' do
      IB::Models::Contract::SECURITY_TYPES.values.each do |type|
        expect {
          x = IB::Models::Contract.new({:sec_type => type})
        }.to_not raise_error

        expect {
          x = IB::Models::Contract.new
          x.sec_type = type
        }.to_not raise_error
      end
    end

    it 'raises on wrong expiry' do
      expect {
        x = IB::Models::Contract.new({:expiry => "foo"})
      }.to raise_error ArgumentError

      expect {
        x = IB::Models::Contract.new
        x.expiry = "foo"
      }.to raise_error ArgumentError
    end

    it 'accepts correct expiry' do
      expect {
        x = IB::Models::Contract.new({:expiry => "200607"})
      }.to_not raise_error

      expect {
        x = IB::Models::Contract.new
        x.expiry = "200607"
      }.to_not raise_error

      expect {
        x = IB::Models::Contract.new({:expiry => 200607})
      }.to_not raise_error

      expect {
        x = IB::Models::Contract.new
        x.expiry = 200607
        x.expiry.should == "200607" # converted to a string
      }.to_not raise_error

    end

    it 'raises on incorrect right (option type)' do
      expect {
        x = IB::Models::Contract.new({:right => "foo"})
      }.to raise_error ArgumentError
      expect {
        x = IB::Models::Contract.new
        x.right = "foo"
      }.to raise_error ArgumentError
    end

    it 'accepts all correct values for right (option type)' do
      ["PUT", "put", "P", "p", "CALL", "call", "C", "c"].each do |right|
        expect {
          x = IB::Models::Contract.new({:right => right})
        }.to_not raise_error

        expect {
          x = IB::Models::Contract.new
          x.right = right
        }.to_not raise_error
      end
    end
  end #instantiation

  context "serialization" do
    subject { stock = IB::Models::Contract.new properties }

    it "serializes long" do
      subject.serialize(:long).should ==
          ["TEST", IB::Models::Contract::SECURITY_TYPES[:stock], "200609", 1234, "PUT", 123, "SMART", nil, "USD", "baz"]
    end

    it "serializes short" do
      subject.serialize(:short).should ==
          ["TEST", IB::Models::Contract::SECURITY_TYPES[:stock], "200609", 1234, "PUT", 123, "SMART", "USD", "baz"]
    end
  end #serialization

end # describe IB::Models::Contract
