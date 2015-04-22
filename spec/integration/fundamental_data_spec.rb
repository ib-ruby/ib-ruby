require 'integration_helper'

describe 'Request Fundamental Data' do
#         :connected => true, :integration => true, :reuters => true do

  before(:all) do
    # use a tws where fundamental data are subscribed
    gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, client_id:1056, connect:true, serial_array: true, host: 'beta'))
    gw.connect if !gw.tws.connected?
    @ib = gw.tws

    @contract = IB::Stock.new( symbol: 'IBM', exchange: 'NYSE', currency: 'USD').query_contract

    @ib.send_message :RequestFundamentalData,
                     :id => 456,
                     :contract => @contract,
                     :report_type => 'snapshot' # 'estimates', 'finstat'

    @ib.wait_for :FundamentalData, 10 # sec
  end

  after(:all) do
    close_connection
  end

  subject { @ib.received[:FundamentalData].first }

  it { expect( @ib.received[:FundamentalData] ). to have_at_least(1).data_message }

  it { is_expected.to be_an IB::Messages::Incoming::FundamentalData }
  its(:request_id) { is_expected.to eq 456 }
  its(:xml) { is_expected.to be_a String }

  it 'responds with XML with relevant data' do
    require 'xmlsimple'
    data_xml = XmlSimple.xml_in(subject.xml, 'ForceArray' => false) #, 'ContentKey' => 'content')
    name = data_xml["CoIDs"]["CoID"].find {|tag| tag['Type'] == 'CompanyName'}['content']
    expect( name ).to match /International Business Machines/
  end
end
