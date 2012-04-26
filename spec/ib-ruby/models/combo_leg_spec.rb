require 'model_helper'

describe IB::Models::ComboLeg,
         :props =>
             {:con_id => 81032967,
              :ratio => 2,
              :side => :buy,
              :exchange => 'CBOE',
              :open_close => :open,
              :short_sale_slot => :broker,
              :designated_location => nil,
              :exempt_code => -1},

         :human => "<ComboLeg: buy 2 con_id 81032967 at CBOE>",

         :errors => {:ratio => ["is not a number"],
                     :side => ["should be buy/sell/short"]},

         :assigns =>
             {:open_close => open_close_assigns,
              :side => buy_sell_short_assigns,
              :designated_location =>
                  {[42, 'FOO', :bar] => /should be blank or orders will be rejected/},
             },

         :aliases =>
             {[:side, :action] => buy_sell_short_assigns,
             } do

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

  context 'DB backed associations', :db => true do
    before(:all) { DatabaseCleaner.clean }

    #before(:all) do
    #  @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
    #  @ib.wait_for :ManagedAccounts
    #  @butterfly = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520
    #  close_connection
    #end

    it 'is a join Model between BAG and its leg Contracts' do
      combo = IB::Bag.new

      google = IB::Option.new(:symbol => 'GOOG',
                              :expiry => 201301,
                              :right => :call,
                              :strike => 500)

      combo.leg_contracts << google
      combo.leg_contracts.should include google
      p combo.save

      #combo.legs.should_not be_empty
      combo.leg_contracts.should include google
      google.combo.should == combo

      leg = combo.legs.first
      google.leg.should == leg

    end
  end

end # describe IB::Models::Contract::ComboLeg
