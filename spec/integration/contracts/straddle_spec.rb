require 'integration_helper'

RSpec.describe "IB::Straddle" do
	let ( :the_option ){ IB::Option.new  symbol: :Estx50, strike: 3000, expiry: IB::Symbols::Futures.next_expiry }
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


	context "initialize with master-option" do
		subject { IB::Straddle.new the_option }
		
		its( :sec_type ) { should eq :bag }
		its( :exchange ) { should eq 'DTB' }
		its( :symbol )   { should eq "Estx50" }
			
	end

	context "initialize with underlying" do
		subject{ IB::Straddle.new( underlying: IB::Symbols::Index.stoxx, strike: 3000) }

		it{ is_expected.to be_a IB::Straddle }
		its( :sec_type ) { should eq :bag }
		its( :exchange ) { should eq 'DTB' }
		its( :symbol )   { should eq "Estx50" }
	end
end
