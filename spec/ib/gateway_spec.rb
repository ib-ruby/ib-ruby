### needs cleaning ####
require 'message_helper'
require 'account_helper'

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
      IB::Gateway.new #  {|gw| puts "test" }
      puts "IB::Gateway"
      puts IB::Gateway.current.inspect
      expect( IB::Gateway.current ).to be_a IB::Gateway 
    end
    it 'initialize accounts', focus:true do
      IB::Gateway.current.connect
      sleep(2)
    end
    subject { IB::Gateway.current.active_accounts }
    it { is_expected.to be_an Array }
    ## indidvidual account
    it { is_expected.to have_at_least(1).items }
    ## Friends&Family + Professional Account (comment out if not appropiate )
    it { is_expected.to have_at_least(2).items } # one advisor + one user
    it " inspect the advisor-user-hierachie " do
     advisor=  IB::Gateway.current.active_accounts.detect{|x| x.advisor? }
     if  IB.db_backed?
     expect( advisor ).to be_a IB::Advisor
     advisor.users.each{|u| expect( u ).to be_a IB::User }
     else
      expect( advisor ).to be_a IB::Account
     end
    end
  end
  # Expose protected methods as public methods.
#  before(:each){ IB::Connection.send(:public, *IB::Connection.protected_instance_methods)  }

#  before(:all){ IB::Connection.new port:7496, logger: mock_logger }
#  after(:all){ IB::Connection.current.disconnect } 
#
#  context 'instantiated and connected'  do
#    subject {IB::Connection.current }
#    it_behaves_like 'Connected Connection without receiver' 
#  end
#
#  context 'connected and operable'  do
#    before(:all) { IB::Connection.current.wait_for :NextValidId, 2 }
#    subject { IB::Connection.current }
#    it_behaves_like 'Connected Connection' 
#  end

end
