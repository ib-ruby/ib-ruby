require 'integration_helper'

describe "Request Account Data", :connected => true, :integration => true do

  before(:all) do
    verify_account
    @ib = IB::Connection.current.presence || IB::Connection.new( OPTS[:connection].merge(:logger => mock_logger))
  end

#  after(:all) { close_connection }

  context "with subscribe option set" do
    before(:all) do
      @ib.send_message :RequestAccountData, :account_code => OPTS[:connection][:user] , :subscribe => true
      @ib.wait_for :AccountDownloadEnd, 5 # sec
    end
    after(:all) do
      @ib.send_message :RequestAccountData, :subscribe => false
      clean_connection
    end

    it_behaves_like 'Valid account data request'
  end
## fails with Advisor-Account
  context "without subscribe option"do
    before(:all) do
      @ib.send_message :RequestAccountData, :account_code => OPTS[:connection][:user] 
      @ib.wait_for :AccountDownloadEnd, 5 # sec
    end

    after(:all) do
      @ib.send_message :RequestAccountData, :subscribe => false
      clean_connection
    end

    it_behaves_like 'Valid account data request'
  end
end # Request Account Data
