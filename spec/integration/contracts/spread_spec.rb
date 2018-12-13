require 'combo_helper'

RSpec.describe "IB::Spread" do
	let ( :the_option ){ IB::Option.new  symbol: :Estx50, strike: 3000, right: :call,  expiry: IB::Symbols::Futures.next_expiry }
		let( :the_spread ) { IB::Calendar.fabricate IB::Symbols::Futures.zn, '3m' }
  before(:all) do
    verify_account
    IB::Connection.new OPTS[:connection].merge(:logger => mock_logger) do |gw|
			gw.subscribe( :Alert ){|y|  puts y.to_human }
		end
  end

  after(:all) do
    close_connection
  end


	context "initialize by fabrication", focus: true do
	
		subject{ the_spread }
		it{ is_expected.to be_a IB::Bag }
		it_behaves_like 'a valid ZN-FUT Combo'
			
	end

	context "serialize the spread", focus: true do 
				subject { the_spread.serialize_rabbit }

				its(:keys){ should eq ["Spread", "legs", "combo_legs", 'misc'] }

				it "serializes the contract" do
					expect( IB::Spread.build_from_json( subject)).to eq the_spread 
				end


				it "json acts as valid transport medium" do
					json_medium =  subject.to_json
					expect( IB::Spread.build_from_json( JSON.parse( json_medium ))).to eq the_spread 
				end

	end

end
