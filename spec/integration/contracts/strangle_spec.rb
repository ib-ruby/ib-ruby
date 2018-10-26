require 'combo_helper'

RSpec.describe "IB::Strangle" do
  before(:all) do
    verify_account
    IB::Connection.new OPTS[:connection].merge(:logger => mock_logger) do |gw|
			gw.subscribe( :Alert ){|y|  puts y.to_human }
		end
  end

  after(:all) do
    close_connection
  end


	context "initialize with underlying" do
		subject { IB::Strangle.new underlying: IB::Symbols::Index.stoxx, p: 3000, c: 3200 }

		it{ is_expected.to be_a IB::Strangle }
		it_behaves_like 'a valid Estx Combo'
		its( :legs )		 { should be_a Array }
			
	end

end
