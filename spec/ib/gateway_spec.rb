### needs cleaning ####
require 'message_helper'
require 'account_helper'
require 'connection_helper'

# enter a second host with a running tws 
# or nil to omit the test of switching to another host
SECOND_HOST= 'beta' # with running tws
EXISTING_HOST = 'server' # without running tws
NONEXISTING_HOST =  '172.28.50.253' # adress valid, no host present
INVALID_HOST =  'tunixtgut' # cannot be translated into a valid ip-address

RSpec.shared_examples_for 'invalid connection' do | host |
	  igc=  IB::Gateway.current
	  if igc.present?

	    igc.change_host host: host
	    igc.prepare_connection
	    igc.connect(1)

	    expect( igc.advisor ).not_to be
	  end

 end

RSpec.shared_examples_for 'fully_initialized_account' do 
	its( :account_values ){ is_expected.to have_at_least(10).account_values }
	its( :portfolio_values ){ is_expected.to have_at_least(1).portfolio_value }

	it "#simple_account_data_scan" do
	  subject.account_values.each {|y| expect( y ).to be_a IB::AccountValue }
	  expect( subject.simple_account_data_scan( 'AccountReady' )).to have(1).account_value
	  expect( subject.simple_account_data_scan( 'StockMarketValue' )).to have_at_least(2).account_values
	  expect( subject.simple_account_data_scan( 'StockMarketValue', 'USD' )).to have(1).account_value
	end

	it "portfolio-positions" do
	  subject.portfolio_values.each {|x| expect( x  ).to be_a IB::PortfolioValue }
	end

end

describe Array do

      before( :all ) do
	IB::Gateway.new :serial_array=> true, logger: mock_logger, client_id:1034, connect: true #  {|gw| puts "test" }
      end

      after(:all){ IB::Gateway.current.disconnect if IB::Gateway.current.present? }

      context "verify new methods", focus: true  do
	let( :gw ){ IB::Gateway.current }
	let( :stock ) {  IB::Stock.new( :con_id => 6327, :symbol => "D" ) }
	it "add stock to advisors contract array" do
	  expect( gw.advisor.contracts ).to be_empty
	  expect{ gw.advisor.contracts.update_or_create( stock, 'con_id') }.to change{ gw.advisor.contracts.size }.by(1)
	  expect( gw.advisor.contracts.last ).to eq stock
	end

	it "update the contract_information " do
	  stoc_dup = IB::Stock.new( :con_id => 6327, :symbol => "C" ) 
	  expect{ gw.advisor.contracts.update_or_create( stoc_dup, 'con_id') }.not_to change{ gw.advisor.contracts.size }
	  expect( gw.advisor.contracts.last ).to eq stoc_dup
	  stock.update_attribute :symbol,'b'
	  expect{ gw.advisor.contracts.update_or_create( stock, 'con_id') }.to change{ gw.advisor.contracts.last.symbol }

	  expect{ gw.advisor.contracts.update_or_create( stoc_dup, 'con_id') }.to change{ gw.advisor.contracts.first.symbol }

	end
	it "update tws-informations" do
	  stock.update_contract do |tws| 
	    expect{ gw.advisor.contracts.update_or_create( tws.contract, 'con_id')}.not_to change {gw.advisor.contracts.size }
	  end
	end



      end
end



describe IB::Gateway do
  after(:all){ IB::Gateway.current.disconnect if IB::Gateway.current.present? }
  before(:all) do
    if IB::Gateway.current.present?
      IB::Gateway.current.disconnect
      IB::Gateway=nil
    else
      puts "no active Gateway detected"
    end

  end

  context "#initialize" do
    it 'without any parameter' do
      IB::Gateway.new :serial_array=> true, logger: mock_logger, client_id:1034 #  {|gw| puts "test" }
      expect( IB::Gateway.current ).to be_a IB::Gateway 
      expect( IB::Gateway.current.advisor).not_to be 
      expect( IB::Gateway.current.active_accounts).to be_empty

    end

    it 'initialized accounts' do
      # logger has to be reassigned to enable the should_log-helper 
      IB::Gateway.current.logger= mock_logger
      IB::Gateway.current.connect
      sleep(2)
      expect( should_log /new demo_advisor detected/ ).to be_truthy
      expect( should_log /new demo_user detected/ ).to be_truthy
      expect( IB::Gateway.current.tws ).to be_a IB::Connection
      expect( IB::Gateway.tws ).to be_a IB::Connection
    end
    subject { IB::Gateway.current.active_accounts }
    it { is_expected.to be_an Array }
    ## indidvidual account
    it { is_expected.to have_at_least(1).account }

    ## Friends&Family + Professional Account (comment out if not appropiate )
    #it { is_expected.to have_at_least(2).items } # one advisor + one user
    it " inspect the advisor-user-hierachie " do
     advisor=  IB::Gateway.current.advisor
     if  IB.db_backed?
     expect( advisor ).to be_a IB::Advisor
     IB::Gateway.current.active_accounts.each{ |u| expect( u ).to be_a IB::User }
     else
      expect( advisor ).to be_a IB::Account
      IB::Gateway.current.active_accounts.each{ |a| expect( a ).to be_a IB::Account }
     end
     ### this might fail on single-User-Logins
     expect( advisor.advisor? ).to be
     IB::Gateway.current.active_accounts.each{|x| expect( x.user? ).to be }
    end
  end

  context "inspect connection"  do
    # Expose protected methods as public methods.
    before(:all) do
      IB::Connection.send(:public, *IB::Connection.protected_instance_methods)  
      # enshure that single tests can be carried out 
      IB::Gateway.new logger: mock_logger , connect: true  unless IB::Gateway.current.present?
    end


    context 'instantiated and connected'  do
      subject { IB::Gateway.tws }
      it_behaves_like 'Connected Connection without receiver' 
    end
    #
    context 'connected and operable'   do
      subject { IB::Gateway.tws }
      it_behaves_like 'Connected Connection' 
    end
    context 'OpenOrder-Handling'  do
      it 'manual sending message and analyse the response' do
	## Important: Place one Order in the specified Account!!
	gw = IB::Gateway.current
	IB::Gateway.current.for_selected_account("DU167349") do | account |
	  expect( account.orders ).to be_empty
          expect{ gw.send_message :RequestAllOpenOrders; sleep 1 }.to change{ account.contracts.size }.by(1)
	  expect( account.contracts.size ).to eq 1
	  expect( account.contracts.first.orders.size ).to eq 1
	  expect( account.orders ).not_to be_empty
	  expect( account.orders.first.contract ).to eq account.contracts.first
	  expect( account.orders ).to eq account.contracts.first.orders
	  # also the OrderState-Status should be updated and have Status submitted
	  expect( account.orders.last.order_states).not_to be_empty
	  expect( account.orders.last.submitted?).to be
	  expect( account.contracts.first.orders.first.submitted? ).to be
	end


    end

    context 'query Account_data' do

      let( :gw ){ IB::Gateway.current }
      it "perform the request" do
	gw.for_active_accounts do |account|
	  expect{ gw.get_account_data( accounts: account) }.to change { account.account_values }
	end
      end
      context IB::Gateway.current do

	subject {  IB::Gateway.current.active_accounts.last }
	it_behaves_like 'fully_initialized_account'
      end

#pp	IB::Connection.current.received
	
      end # it
    end #context

    context "switch to another host" do
      it "change accounts" do
	if SECOND_HOST.present?
	  igc=  IB::Gateway.current
	  old_advisor =  igc.advisor
	  old_users = igc.active_accounts

	  igc.change_host host: SECOND_HOST
	  igc.prepare_connection
	  igc.connect

	  expect( igc.advisor ).not_to eq old_advisor
	  expect( igc.active_accounts).not_to eq old_users
	end
      end
      [ EXISTING_HOST, NONEXISTING_HOST ,INVALID_HOST].each do |host|
	it_should_behave_like 'invalid connection' , host   if host.present?
      end
    end
  end
end
