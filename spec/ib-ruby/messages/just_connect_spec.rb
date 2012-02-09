require 'message_helper'

describe IB::Messages do

  context 'Normal message exchange at any connection', :connected => true do

    before(:all) do
      connect_and_receive :NextValidID, :OpenOrderEnd, :Alert
      wait_for(2) { not @received[:OpenOrderEnd].empty? }
    end

    after(:all) { close_connection }

    it 'receives :NextValidID message' do
      @received[:NextValidID].should_not be_empty
    end

    it 'receives :OpenOrderEnd message' do
      @received[:OpenOrderEnd].should_not be_empty
    end

    it 'logs connection notification' do
      should_log /Connected to server, version: 53, connection time/
    end

    it 'logs next valid order id' do
      should_log /Got next valid order id/
    end

  end # Normal message exchange at any connection
end # describe IB::Messages
