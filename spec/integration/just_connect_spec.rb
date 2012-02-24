require 'integration_helper'

describe IB::Messages do

  context 'Normal message exchange at any connection', :connected => true do

    before(:all) do
      connect_and_receive :NextValidID, :OpenOrderEnd, :Alert
      wait_for(2) { received? :OpenOrderEnd }
    end

    after(:all) { close_connection }

    it 'receives :NextValidID message' do
      @received[:NextValidID].should_not be_empty
      @received[:NextValidID].first.should be_an IB::Messages::Incoming::NextValidID
    end

    it 'receives :OpenOrderEnd message' do
      @received[:OpenOrderEnd].should_not be_empty
      @received[:OpenOrderEnd].first.should be_an IB::Messages::Incoming::OpenOrderEnd
    end

    it 'logs connection notification' do
      should_log /Connected to server, version: 53, connection time/
    end

    it 'logs next valid order id' do
      should_log /Got next valid order id/
    end

  end # Normal message exchange at any connection
end # describe IB::Messages
