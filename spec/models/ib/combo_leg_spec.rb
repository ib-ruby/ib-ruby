require 'model_helper'

describe IB::ComboLeg,
  :props =>
  {:con_id => 81032967,
   :ratio => 2,
   :side => :buy,
   :exchange => 'CBOE',
   :open_close => :open,
   :short_sale_slot => :broker,
   :designated_location => '',
   :exempt_code => -1},

  :human => "<ComboLeg: buy 2 con_id 81032967 at CBOE>",

  :errors => {:ratio => ["is not a number"],
              :side => ["should be buy/sell/short"]},

  :assigns =>
  {:open_close => open_close_assigns,
   :side => buy_sell_short_assigns,
   :short_sale_slot => codes_and_values_for(:short_sale_slot),
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

  it_behaves_like 'Model with valid defaults'
  it_behaves_like 'Self-equal Model'

  context "serialization" do
    subject { IB::ComboLeg.new props }

    it "serializes short" do
      subject.serialize.should == [81032967, 2, "BUY", "CBOE"]
    end

    it "serializes extended" do
      subject.serialize(:extended).should ==
        [81032967, 2, "BUY", "CBOE", 1, 1, '', -1]
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

    before(:each) do
      @combo = IB::Bag.new

      @google = IB::Option.new(:symbol => 'GOOG',
                               :expiry => 201301,
                               :right => :call,
                               :strike => 500)
    end

    it 'saves associated BAG and leg Contract' do

      combo_leg = IB::ComboLeg.new :con_id => 454, :weight => 3
      combo_leg.should be_valid

      # Assigning both associations for a join model
      combo_leg.combo = @combo
      combo_leg.leg_contract = @google

      combo_leg.save.should == true
      @combo.should_not be_new_record
      @google.should_not be_new_record

      combo_leg.combo.should == @combo
      combo_leg.leg_contract.should == @google
      @combo.legs.should include combo_leg
      @combo.leg_contracts.should include @google
      @google.leg.should == combo_leg
      @google.combo.should == @combo

    end

    it 'loads ComboLeg together with associated BAG and leg Contract' do

      combo_leg = IB::ComboLeg.where(:con_id => 454).first
      combo_leg.should be_valid

      combo = combo_leg.combo
      google = combo_leg.leg_contract
      #combo.should == @combo # NOT equal, different legs
      google.should == @google

      combo.legs.should include combo_leg
      combo.leg_contracts.should include google
      google.leg.should == combo_leg
      google.combo.should == combo
    end


    it 'creates ComboLeg indirectly through associated BAG and leg Contract' do

      @combo.leg_contracts << @google
      @combo.leg_contracts.should include @google
      @combo.valid?.should be_true
      @combo.save.should be_true

      #combo.legs.should_not be_empty
      @combo.leg_contracts.should include @google
      @google.combo.should == @combo

      leg = @combo.legs.first
      @google.leg.should == leg

    end
  end

end # describe IB::ComboLeg
