require 'integration_helper'

# Define butterfly
def butterfly symbol, expiry, right, *strikes
	ib = IB::Connection.current
  raise 'Unable to create butterfly, no connection' unless ib && ib.connected?

  legs = strikes.zip([1, -2, 1]).map do |strike, weight|
    # Create contract
    contract = IB::Option.new :symbol => symbol,
                              :expiry => expiry,
                              :right => right,
                              :strike => strike

    # Find out contract's con_id
    ib.clear_received :ContractData, :ContractDataEnd
    ib.send_message :RequestContractData, :id => strike, :contract => contract
    ib.wait_for :ContractDataEnd, 3
    con_id = ib.received[:ContractData].last.contract.con_id

    # Create Comboleg from con_id and weight
    IB::ComboLeg.new :con_id => con_id, :weight => weight
  end

  # Return butterfly Combo
  IB::Bag.new :symbol => symbol,
              :currency => "USD", # Only US options in combo Contracts
              :exchange => "SMART",
              :combo_legs => legs
end

RSpec.shared_examples 'a valid Estx Combo' do

		its( :sec_type ) { should eq :bag }
		its( :exchange ) { should eq 'DTB' }
		its( :symbol )   { should eq "Estx50" }
		its( :market_price )   { should be_a Numeric }
end

