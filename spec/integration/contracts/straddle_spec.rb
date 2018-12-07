require 'combo_helper'
STRIKE =  3200
RSpec.describe "IB::Straddle" do
	let ( :the_option ){ IB::Option.new  symbol: :Estx50, right: :put, strike: STRIKE, expiry: IB::Symbols::Futures.next_expiry }
	let ( :the_bag ){ IB::Symbols::Combo::stoxx_straddle }
  before(:all) do
    verify_account
    IB::Connection.new OPTS[:connection].merge(:logger => mock_logger) do |gw|
			gw.subscribe( :Alert ){|y|  puts y.to_human }
		end
  end

  after(:all) do
    close_connection
  end


	context "fabricate with master-option" do
		subject { IB::Straddle.fabricate the_option }
		it{ is_expected.to be_a IB::Bag }
		it_behaves_like 'a valid Estx Combo'
		
			
	end

	context "build with underlying" do
		subject{ IB::Straddle.build from: IB::Symbols::Index.stoxx, strike: STRIKE , expiry: IB::Symbols::Futures.next_expiry  }

		it{ is_expected.to be_a IB::Spread  }
		it_behaves_like 'a valid Estx Combo'
	end
	context "build with option"  do
		subject{ IB::Straddle.build from: the_option, strike: STRIKE }

		it{ is_expected.to be_a IB::Spread }
		it_behaves_like 'a valid Estx Combo'
	end
end
