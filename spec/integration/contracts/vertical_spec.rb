require 'combo_helper'

RSpec.describe "IB::Vertical" do
	let ( :the_option ){ IB::Option.new  right: :put, symbol: :Estx50, strike: 3000, expiry: IB::Symbols::Futures.next_expiry }
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
		subject { IB::Vertical.fabricate the_option , sell: 3200}
		it{ is_expected.to be_a IB::Bag }
		it_behaves_like 'a valid Estx Combo'
		
			
	end

	context "build with underlying"  do
		subject{ IB::Vertical.build from: IB::Symbols::Index.stoxx, buy: 3000, sell: 3200, expiry: IB::Symbols::Futures.next_expiry  }

		it{ is_expected.to be_a IB::Spread }
		it_behaves_like 'a valid Estx Combo'
	end
	context "build with option" do
		subject{ IB::Vertical.build from: the_option, buy: 3200 }

		it{ is_expected.to be_a IB::Spread }
		it_behaves_like 'a valid Estx Combo'
	end
end
