require File.join(File.dirname(__FILE__), %w[spec_helper])

describe IB::Datatypes::Contract do

  context "instantiation" do

    it 'instantiates without options' do
      x = IB::Datatypes::Contract.new
      x.should_not be_nil
    end

    it 'allows setting attributes' do
      expect {
        x = IB::Datatypes::Contract.new
        x.symbol = "TEST"
        x.sec_type = IB::Datatypes::Contract::SECURITY_TYPES[:stock]
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
        x = IB::Datatypes::Contract.new({:sec_type => "asdf"})
      }.to raise_error ArgumentError

      expect {
        x = IB::Datatypes::Contract.new
        x.sec_type = "asdf"
      }.to raise_error ArgumentError

    end

    it 'accepts pre-determined security types' do
      IB::Datatypes::Contract::SECURITY_TYPES.values.each do |type|
        expect {
          x = IB::Datatypes::Contract.new({:sec_type => type})
        }.to_not raise_error

        expect {
          x = IB::Datatypes::Contract.new
          x.sec_type = type
        }.to_not raise_error
      end
    end

    it 'raises on wrong expiry' do
      expect {
        x = IB::Datatypes::Contract.new({:expiry => "foo"})
      }.to raise_error ArgumentError

      expect {
        x = IB::Datatypes::Contract.new
        x.expiry = "foo"
      }.to raise_error ArgumentError
    end

    it 'accepts correct expiry' do
      expect {
        x = IB::Datatypes::Contract.new({:expiry => "200607"})
      }.to_not raise_error

      expect {
        x = IB::Datatypes::Contract.new
        x.expiry = "200607"
      }.to_not raise_error

      expect {
        x = IB::Datatypes::Contract.new({:expiry => 200607})
      }.to_not raise_error

      expect {
        x = IB::Datatypes::Contract.new
        x.expiry = 200607
        x.expiry.should == "200607" # converted to a string
      }.to_not raise_error

    end

    it 'raises on incorrect right (option type)' do
      expect {
        x = IB::Datatypes::Contract.new({:right => "foo"})
      }.to raise_error ArgumentError
      expect {
        x = IB::Datatypes::Contract.new
        x.right = "foo"
      }.to raise_error ArgumentError
    end

    it 'accepts all correct values for right (option type)' do
      ["PUT", "put", "P", "p", "CALL", "call", "C", "c"].each do |right|
        expect {
          x = IB::Datatypes::Contract.new({:right => right})
        }.to_not raise_error

        expect {
          x = IB::Datatypes::Contract.new
          x.right = right
        }.to_not raise_error
      end
    end
  end #instantiation

  context "serialization" do
    let(:stock) do
      stock = IB::Datatypes::Contract.new
      stock.symbol = "TEST"
      stock.sec_type = IB::Datatypes::Contract::SECURITY_TYPES[:stock]
      stock.expiry = 200609
      stock.strike = 1234
      stock.right = "put"
      stock.multiplier = 123
      stock.exchange = "SMART"
      stock.currency = "USD"
      stock.local_symbol = "baz"
      stock
    end

    it "serializes long" do
      stock.serialize_long(20).should ==
          ["TEST", IB::Datatypes::Contract::SECURITY_TYPES[:stock], "200609", 1234, "PUT", 123, "SMART", nil, "USD", "baz"]
    end

    it "serializes short" do
      stock.serialize_short(20).should ==
          ["TEST", IB::Datatypes::Contract::SECURITY_TYPES[:stock], "200609", 1234, "PUT", 123, "SMART", "USD", "baz"]
    end

  end #serialization

end # describe IB::Datatypes::Contract
