require 'order_helper'

#OPTS[:silent] = false

def butterfly symbol, expiry, right, *strikes
  raise 'No Connection!' unless @ib && @ib.connected?

  legs = strikes.zip([1, -2, 1]).map do |strike, weight|
    # Create contract
    contract = IB::Models::Contract::Option.new :symbol => symbol,
                                                :expiry => expiry,
                                                :right => right,
                                                :strike => strike
    # Find out contract's con_id
    @ib.clear_received :ContractData, :ContractDataEnd
    @ib.send_message :RequestContractData, :id => strike, :contract => contract
    @ib.wait_for :ContractDataEnd, 3
    con_id = @ib.received[:ContractData].last.contract.con_id

    # Create Comboleg from con_id and weight
    IB::Models::ComboLeg.new :con_id => con_id, :weight => weight
  end

  # Create new Combo contract
  IB::Models::Contract::Bag.new :symbol => symbol,
                                :currency => "USD", # Only US options in combo Contracts
                                :exchange => "SMART",
                                :legs => legs
end

describe "Combo Order", :connected => true, :integration => true do

  before(:all) { verify_account }

  context "Limit" do # , :if => :us_trading_hours
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId
      @ib.clear_received # to avoid conflict with pre-existing Orders

      @combo = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520

      place_order @combo, :limit_price => 0.01 #, :what_if => true
      @ib.wait_for [:OpenOrder, 3], [:OrderStatus, 2], 5
    end

    after(:all) { close_connection }

    it_behaves_like 'Placed Order'
  end # Limit
end # Combo Orders
