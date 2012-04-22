require 'model_helper'

describe IB::Models::ComboLeg do

  let(:props) do
    {:con_id => 81032967,
     :ratio => 2,
     :side => :buy,
     :exchange => 'CBOE',
     :open_close => :open,
     :short_sale_slot => :broker,
     :designated_location => nil,
     :exempt_code => -1}
  end

  let(:human) do
    "<ComboLeg: buy 2 con_id 81032967 at CBOE>"
  end

  let(:errors) do
    {:ratio => ["is not a number"],
     :side => ["should be buy/sell/short"]}
  end

  let(:assigns) do
    {:open_close => open_close_assigns,
     :side => buy_sell_short_assigns,
     :designated_location =>
         {[42, 'FOO', :bar] => /should be blank or orders will be rejected/},
    }
  end

  let(:aliases) do
    {[:side, :action] => buy_sell_short_assigns,
    }
  end

  it 'has combined weight accessor' do
    leg = IB::ComboLeg.new props
    leg.weight = -3
    leg.side.should == :sell
    leg.ratio.should == 3
    leg.weight = 5
    leg.side.should == :buy
    leg.ratio.should == 5
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context "serialization" do
    subject { IB::ComboLeg.new props }

    it "serializes short" do
      subject.serialize.should == [81032967, 2, "BUY", "CBOE"]
    end

    it "serializes extended" do
      subject.serialize(:extended).should ==
          [81032967, 2, "BUY", "CBOE", 1, 1, nil, -1]
    end
  end #serialization

end # describe IB::Models::Contract::ComboLeg
