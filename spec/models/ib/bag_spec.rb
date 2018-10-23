require 'model_helper'

describe IB::Bag do

        let(:props ){ {:symbol => 'GOOG',
              :exchange => 'SMART',
              :currency => 'USD',
              :combo_legs => [IB::ComboLeg.new(:con_id => 81032967, :weight => 1),
                        IB::ComboLeg.new(:con_id => 81032968, :weight => -2),
                        IB::ComboLeg.new(:con_id => 81032973, :weight => 1)]
             } }

#         :human => "<Bag: GOOG SMART USD legs: 81032967|1,81032968|-2,81032973|1 >",
#
#         :errors =>
#             {:legs => ["legs cannot be empty"]},
#
#         :assigns =>
#             {:expiry =>
#                  {[nil, ''] => '',
#                   [20060913, '20060913', 200609, '200609', 2006, :foo, 'bar'] =>
#                       /should be blank/},
#
#              :sec_type =>
#                  {['BAG', :bag] => :bag,
#                   IB::CODES[:sec_type].reject { |k, _| k == :bag }.to_a =>
#                       /should be a bag/},
#
#              :right =>
#                  {['?', :none, '', '0'] => :none,
#                   ["PUT", :put, "CALL", "C", :call, :foo, 'BAR', 42] =>
#                       /should be none/},
#
#              :exchange => string_upcase_assigns.merge(
#                  [:smart, 'SMART', 'smArt'] => 'SMART'),
#
#              :primary_exchange =>string_upcase_assigns.merge(
#                  [:SMART, 'SMART'] => /should not be SMART/),
#
#              [:symbol, :local_symbol] => string_assigns,
#
#              :multiplier => to_i_assigns,
#             } }
#
  it_behaves_like 'Model with valid defaults'
  it_behaves_like 'Self-equal Model'

  context 'properly initiated' do
    subject { IB::Bag.new props }

    it_behaves_like 'Contract'

    it 'has extra legs_description accessor' do
      subject.legs_description.should == "81032967|1,81032968|-2,81032973|1"
    end
  end

  it 'correctly defines Contract type (sec_type) for Bag contract' do
    [IB::Contract.new(:sec_type => :bag),
     IB::Contract.new(:sec_type => 'BAG'),
     IB::Bag.new
    ].each do |contract|
      expect( contract ).to be_bag
      expect( contract ).not_to  be_bond
      expect( contract ).not_to be_stock
      expect( contract ).not_to be_option
    end
  end

end # describe IB::Bag
