require 'integration_helper'

describe 'Request Fundamental Data',
         :connected => true, :integration => true, :reuters => true do

  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

    @contract = IB::Contract.new :symbol => 'IBM',
                                 :exchange => 'NYSE',
                                 :currency => 'USD',
                                 :sec_type => 'STK'

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

  it { @ib.received[:FundamentalData].should have_at_least(1).data_message }

  it { should be_an IB::Messages::Incoming::FundamentalData }
  its(:request_id) { should == 456 }
  its(:xml) { should be_a String }

  it 'responds with XML with relevant data' do
    require 'xmlsimple'
    data_xml = XmlSimple.xml_in(subject.xml, 'ForceArray' => false) #, 'ContentKey' => 'content')
    name = data_xml["CoIDs"]["CoID"].find {|tag| tag['Type'] == 'CompanyName'}['content']
    name.should =~ /International Business Machines/
  end
end
