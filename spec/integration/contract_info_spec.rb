require 'integration_helper'

RSpec.shared_examples_for 'valid ContractData Request' do
			its( :request_id ){ is_expected.to eq @request_id  }
			its( :contract ){ is_expected.to be_valid.and be ==  contract   }
			its( :buffer ){ is_expected.to be_empty } # all transmitted data are recognized

end
describe "Request Contract Info" do 

  before(:all) do
    verify_account
    ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
    ib.wait_for :NextValidId
  end

  after(:all) { close_connection }

  context "Request Stock data" do

    before(:all) do
			ib =  IB::Connection.current
      @request_id =  ib.send_message :RequestContractData, :contract => IB::Symbols::Stocks.aapl
      ib.wait_for :ContractDataEnd, 3 # sec
    end
	

    after(:all) { clean_connection } # Clear logs and message collector
  
		let( :contract  ) { IB::Symbols::Stocks.aapl }


		context IB::Connection do
			subject { IB::Connection.current  }
		  it { expect( subject.received[:ContractData] ).to have_exactly(1).contract_data }
			it { expect( subject.received[:ContractDataEnd] ).to have_exactly(1).contract_data_end }
		end

		context IB::Messages::Incoming::ContractData do
			subject { IB::Connection.current.received[:ContractData].first }	

			it_behaves_like 'valid ContractData Request'

    it 'receives Contract Data with extended fields' do

			contract = subject.contract
			detail = subject.contract_detail

      expect( contract.symbol).to  eq contract.symbol
      expect( contract.local_symbol).to  match contract.symbol
      expect( contract.con_id).to  be_an Integer
      expect( contract.expiry).to be_empty.or be_nil 
      expect( contract.exchange).to  eq 'SMART'

      expect( detail.market_name).to  match /NMS|USSTARS/
      expect( contract.trading_class).to  match /NMS|USSTARS/
      expect( detail.long_name).to  eq 'APPLE INC'
      expect( detail.industry).to  eq 'Technology'
      expect( detail.category).to  eq 'Computers'
      expect( detail.subcategory).to  eq 'Computers'
      expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.valid_exchanges).to  match /SMART|EBS/
      expect( detail.order_types).to  be_a String
      expect( detail.price_magnifier).to  eq 1
      expect( detail.min_tick).to  eq 0.01
      end
		end
	end
#
  context "Request Option contract data" do
#
    before(:all) do
			ib =  IB::Connection.current
      @request_id =  ib.send_message :RequestContractData, :contract => IB::Symbols::Options.ge20
      ib.wait_for :ContractDataEnd, 3 # sec
    end
    after(:all) { clean_connection } # Clear logs and message collector
		let( :contract  ) { IB::Symbols::Options.ge20 }

		context IB::Messages::Incoming::ContractData do
			subject { IB::Connection.current.received[:ContractData].first }	

			it_behaves_like 'valid ContractData Request'

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      detail = subject.contract_detail

      expect( contract.symbol).to  eq 'GE'
      expect( contract.local_symbol).to  match  /^GE[ ]{4}[0-9]{6}C[0-9]{8}$/
      expect( contract.last_trading_day).to  match /^\d{4}-\d{2}-\d{2}$/
      expect( contract.exchange).to  eq 'SMART'
      expect( contract.con_id).to  be_an Integer

      expect( detail.market_name).to  eq 'GE'
      expect( contract.trading_class).to  eq 'GE'
      expect( detail.long_name).to  eq 'GENERAL ELECTRIC CO'
      expect( detail.industry).to  eq 'Industrial'
      expect( detail.category).to  eq 'Miscellaneous Manufactur'
      expect( detail.subcategory).to  eq 'Diversified Manufact Op'
      expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.valid_exchanges).to  match /CBOE/
      expect( detail.order_types).to  be_a String
      expect( detail.price_magnifier).to  eq 1
      expect( detail.min_tick).to  eq 0.01
    end
		end
	end
	context "Request OptionChain  by expiry"  do
    before(:all) do
			ib =  IB::Connection.current
			ib.clear_received :ContractData
      @request_id =  ib.send_message :RequestContractData, :contract => IB::Symbols::Options.ibm_lazy_expiry
      ib.wait_for :ContractDataEnd, 3 # sec
		end

		it "has recieved multible contracts" do
			ib =  IB::Connection.current
			
			expect( ib.received[:ContractData]  ).to have_at_least(2).records
		end
	end

	context "Request OptionChain  by strike"  do
    before(:all) do
			ib =  IB::Connection.current
			ib.clear_received :ContractData
      @request_id =  ib.send_message :RequestContractData, :contract => IB::Symbols::Options.ibm_lazy_strike
      ib.wait_for :ContractDataEnd, 3 # sec
		end

		it "has recieved multible contracts" do
			ib =  IB::Connection.current
			
			expect( ib.received[:ContractData]  ).to have_at_least(2).records
		end

#		context IB::Messages::Incoming::ContractData do
#			subject { IB::Connection.current.received[:ContractData].first }	


	end
  context "Request Forex contract data"   do

    before(:all) do
			ib =  IB::Connection.current
			ib.clear_received :ContractData
      @request_id = ib.send_message :RequestContractData, :contract =>  IB::Symbols::Forex.eurusd
      ib.wait_for :ContractDataEnd, 3 # sec
    end

    after(:all) { clean_connection } # Clear logs and message collector
		let( :contract  ) { IB::Symbols::Forex.eurusd }

		context IB::Messages::Incoming::ContractData do
			subject { IB::Connection.current.received[:ContractData].first }	

			it_behaves_like 'valid ContractData Request'
    
    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      detail = subject.contract_detail

      expect( contract.symbol).to  eq 'EUR'
      expect( contract.local_symbol).to  eq 'EUR.USD'
      expect( contract.expiry).to be_empty.or be_nil 
      expect( contract.exchange).to  eq 'IDEALPRO'
      expect( contract.con_id).to  be_an Integer

      expect( detail.market_name).to  eq 'EUR.USD'
      expect( contract.trading_class).to  eq 'EUR.USD'
      expect( detail.long_name).to  match /European Monetary Union [Ee]uro/
      expect( detail.industry).to  eq ''
      expect( detail.category).to  eq ''
      expect( detail.subcategory).to  eq ''
      expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.valid_exchanges).to match /IDEALPRO/
      expect( detail.order_types).to  be_a String
      expect( detail.price_magnifier).to  eq 1
      expect( detail.min_tick).to  be <= 0.0001
    end
		end
	end 



  context "Request Futures contract data"  do

    before(:all) do
			ib =  IB::Connection.current
      @request_id = ib.send_message :RequestContractData, :contract => IB::Symbols::Futures.ym # Mini Dow Jones Industrial IB::Symbols::Forex.eurusd
      ib.wait_for :ContractDataEnd, 3 # sec
    end

    after(:all) { clean_connection } # Clear logs and message collector
		let( :contract  ) { IB::Symbols::Futures.ym }
		context IB::Messages::Incoming::ContractData do
			subject { IB::Connection.current.received[:ContractData].first }	

			it_behaves_like 'valid ContractData Request'

			it 'receives Contract Data with extended fields' do
				contract = subject.contract
				detail = subject.contract_detail

				expect( contract.symbol).to  eq 'YM'
				expect( contract.local_symbol).to  match /YM/
				expect( contract.expiry).to  match Regexp.new(IB::Symbols::Futures.next_expiry)
				expect( contract.exchange).to  eq 'ECBOT'
				expect( contract.con_id).to  be_an Integer

				expect( detail.market_name).to  eq 'YM'
				expect( contract.trading_class).to  eq 'YM'
				expect( detail.long_name).to  eq 'Mini Sized Dow Jones Industrial Average $5'
				expect( detail.industry).to  eq ''
				expect( detail.category).to  eq ''
				expect( detail.subcategory).to  eq ''
				expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
				expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
				expect( detail.valid_exchanges).to  match /ECBOT/
				expect( detail.order_types).to  be_a String
				expect( detail.price_magnifier).to  eq 1
				expect( detail.min_tick).to  eq 1
			end
		end
	end
end 
    
#
#  context "Request Bond data",  pending: true do
#
#    before(:all) do
#      @contract = IB::Symbols::Bonds[:wag] # Wallgreens bonds (multiple)
#      @ib.send_message :RequestContractData, :id => 158, :contract => @contract
#      @ib.wait_for :ContractDataEnd, 5 # sec
#    end
#
#    after(:all) { clean_connection } # Clear logs and message collector
#
#    subject { @ib.received[:BondContractData].first }
#
#    it { @ib.received[:BondContractData].should have_at_least(1).contract_data }
#    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }
#
#    it 'receives Contract Data for requested contract' do
#      subject.request_id.should == 158
#      # subject.contract.should == @contract # symbol is blanc in returned Bond contracts
#      subject.contract.should be_valid
#    end
#
#    it 'receives Contract Data with extended fields' do
#      contract = subject.contract
#      detail = subject.contract_detail
#
#      contract.sec_type.should == :bond
#      contract.symbol.should == ''
#      contract.con_id.should be_an Integer
#
#      detail.cusip.should be_a String
#      detail.desc_append.should =~ /WAG/ # "WAG 4 7/8 08/01/13" or similar
#      detail.trading_class.should =~ /IBCID/ # "IBCID113527163"
#      detail.sec_id_list.should be_a Hash
#      detail.sec_id_list.should have_key "CUSIP"
#      detail.sec_id_list.should have_key "ISIN"
#      detail.valid_exchanges.should be_a String
#      detail.order_types.should be_a String
#      detail.min_tick.should == 0.001
#    end
#  end # Request Forex data
#end # Contract Data
#

__END__
