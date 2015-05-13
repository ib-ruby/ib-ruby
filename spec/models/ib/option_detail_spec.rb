require 'spec_helper'
require 'integration_helper'

 EXPIRY = '201506'

describe IB::OptionDetail do

  before(:all) do
    # use a tws where the appropiate permissions exist
    gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, client_id:1056, connect:true, serial_array: false, host: 'beta'))
    gw.connect if !gw.tws.connected?
    @ib=gw.tws
  end
  let( :us_option ){ IB::Option.new( symbol: 'RRD', strike: 20, expiry: EXPIRY, right: :put) }
  let( :eu_option ){ IB::Option.new( symbol: 'BEI', strike: 80, expiry: EXPIRY, currency:'EUR', right: :put, exchange: 'DTB' ) }
  let( :option_detail ){ IB::OptionDetail.new }
  context "proper model" do

    it 'belongs to an option' do
      option = eu_option
      expect( option.verify ).to eq 1   # valid Option Contract
      expect( option.option_detail ).to be_nil 
      option.option_detail =  option_detail   ## the assignment has to be done twofold
      option_detail.option =  option

      expect( option.option_detail ).to eq option_detail
      expect( option_detail.option ).to eq option
    end

    it 'requests snapshot OptionDetails for one contract' do  ## works outside of trading hours
      option  = us_option
      expect{ option.verify }.to change{ option.con_id } 
      option.update_option_details snapshot:true
      puts option.option_detail.inspect
      expect( option.option_detail.greeks? ).to be_truthy
    end
    
    it 'requests snapshot OptionDetails for one contract' do  ## works outside of trading hours
      option  = eu_option
      expect{ option.verify }.to change{ option.con_id } 
      option.update_option_details snapshot:false
      puts option.option_detail.inspect
      expect( option.option_detail.complete? ).to be_truthy
    end

  end


end

