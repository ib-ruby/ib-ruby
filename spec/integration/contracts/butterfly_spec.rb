require 'combo_helper'

RSpec.describe "IB::Butterfly" do
	let ( :the_option ){ IB::Option.new  symbol: :Estx50, strike: 3000, right: :call,  expiry: IB::Symbols::Futures.next_expiry }
	let ( :the_bag ){ IB::Symbols::Combo::stoxx_butterfly }
  before(:all) do
    verify_account
    IB::Connection.new OPTS[:connection].merge(:logger => mock_logger) do |gw|
			gw.subscribe( :Alert ){|y|  puts y.to_human }
		end
  end

  after(:all) do
    close_connection
  end


	context "initialize with master-option" do
		subject { IB::Butterfly.make the_option, back: 3050, front: 2950 }
		it{ is_expected.to be_a IB::Butterfly }
		it_behaves_like 'a valid Estx Combo'
		
			
	end

	context "initialize with underlying" do
		subject{ IB::Butterfly.make( underlying: IB::Symbols::Index.stoxx, strike: 3000, front: 2950 , back: 3050 ) }

		it{ is_expected.to be_a IB::Butterfly }
		it_behaves_like 'a valid Estx Combo'
	end
end
