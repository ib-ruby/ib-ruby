### needs cleaning ####
require 'message_helper'
require 'account_helper'
require 'connection_helper'

describe IB::Gateway do
  after(:all){ IB::Gateway.current.disconnect if IB::Gateway.current.present? }
  before(:all) do
    if IB::Gateway.current.present?
      IB::Gateway.current.disconnect
      IB::Gateway=nil
    else
      puts "no active Gateway detected"
    end

    if IB::Connection.current.present?
      IB::Connection.current.disconnect
      IB::Connection =  nil
    else
      puts "no active Connection Object"
    end
  end

  context "#initialize", focus:true do
    it 'without any parameter' do
      IB::Gateway.new logger: mock_logger #  {|gw| puts "test" }
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
     expect( advisor.advisor? ).to be
     IB::Gateway.current.active_accounts.each{|x| expect( x.user? ).to be }
    end
  end

  context "inspect connection" , focus:true do
    # Expose protected methods as public methods.
    before(:all){ IB::Connection.send(:public, *IB::Connection.protected_instance_methods)  }

    context 'instantiated and connected'  do
      subject { IB::Connection.current }
      it_behaves_like 'Connected Connection without receiver' 
    end
    #
    context 'connected and operable'  do
      subject { IB::Connection.current }
      it_behaves_like 'Connected Connection' 
    end
  end

end
