### needs cleaning ####
require 'message_helper'
require 'account_helper'
require 'connection_helper'

# enter a second host with a running tws 
# or nil to omit the test of switching to another host
SECOND_HOST= 'beta'

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
      IB::Gateway.new :serial_array=> true, logger: mock_logger #  {|gw| puts "test" }
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


    context 'query Account_data' do
      before(:all) do
	account_id = IB::Gateway.current.active_accounts.first.account
	Ib::Gateway.tws.send_message :RequestAccountData, :subscribe => true, :account_code => account_id

      end
      it "perform the request" do
	expect( IB::Gateway.current.active_accounts.first).to be_a IB::Account 

	sleep 2
      end
      subject {  IB::Gateway.current.active_accounts.first }
	its( :account_values){ is_expected.to have_at_least(10).account_values }
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

    context 'OpenOrder-Handling' do
      it 'manual sending message and analyse the response' do
	## Important: Place an Order in the specified Account!!
	tws = IB::Gateway.current.tws
	IB::Gateway.current.for_selected_account("DU167349") do | account |
	  expect( account.orders ).to be_empty
          expect{ tws.send_message :RequestAllOpenOrders; sleep 1 }.to change{ account.contracts.size }.by(1)
	  expect( account.contracts.size ).to eq 1
	  expect( account.contracts.first.orders.size ).to eq 1
	  expect( account.orders ).not_to be_empty
	  expect( account.orders.first.contract ).to eq account.contracts.first
	  expect( account.orders ).to eq account.contracts.first.orders
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
    end
  end

end
