require 'integration_helper'

describe "Request Account Data", :connected => true, :integration => true do

  before(:all) do
    verify_account
    connect_and_receive(:Alert, :AccountValue, :AccountDownloadEnd,
                        :PortfolioValue, :AccountUpdateTime)
  end

  after(:all) { close_connection }

  context "with subscribe option set" do
    before(:all) do
      @ib.send_message :RequestAccountData, :subscribe => true
      wait_for(5) { received? :AccountDownloadEnd }
    end
    after(:all) do
        @ib.send_message :RequestAccountData, :subscribe => false
        clean_connection
      end

    it_behaves_like 'Valid account data request'
  end

  context "without subscribe option" do
    before(:all) do
      @ib.send_message :RequestAccountData
      wait_for(5) { received? :AccountDownloadEnd }
    end

    after(:all) do
      @ib.send_message :RequestAccountData, :subscribe => false
      clean_connection
    end

    it_behaves_like 'Valid account data request'
  end
end # Request Account Data
