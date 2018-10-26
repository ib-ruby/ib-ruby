require 'combo_helper'

RSpec.describe "IB::Calendar" do
	let ( :the_option ){ IB::Option.new  symbol: :Estx50, strike: 3000, right: :call,  expiry: IB::Symbols::Futures.next_expiry }
	let ( :the_bag ){ IB::Symbols::Combo::stoxx_calendar }
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
		subject { IB::Calendar.new the_option, back: '1m' }
		it{ is_expected.to be_a IB::Calendar }
		it_behaves_like 'a valid Estx Combo'
		
			
	end

	context "initialize with underlying" do
		subject{ IB::Calendar.new( underlying: IB::Symbols::Index.stoxx, strike: 3000, front:IB::Symbols::Futures.next_expiry , back: '1m' ) }

		it{ is_expected.to be_a IB::Calendar }
		it_behaves_like 'a valid Estx Combo'
	end
end
