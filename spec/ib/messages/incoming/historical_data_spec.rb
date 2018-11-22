require 'message_helper'

RSpec.shared_examples_for 'HistoricalData message' do
  it { is_expected.to be_an IB::Messages::Incoming::HistoricalData }
  its(:message_type) { is_expected.to eq :HistoricalData }
  its(:message_id) { is_expected.to eq 17 }
	its(:request_id) {is_expected.to eq 123}
	its( :count ){ is_expected.to be_a Integer }
  its(:start_date) { is_expected.to be_a DateTime }
	its(:end_date) { is_expected.to be_a DateTime }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 17 
    expect( subject.class.message_type).to eq :HistoricalData
  end
end

RSpec.shared_examples_for "Bars" do

end

describe IB::Messages::Incoming::HistoricalData do


  context 'Instantiated with buffer data'  do
    subject do
   IB::Messages::Incoming::HistoricalData.new ["123", "20181120  17:53:13", "20181121  17:53:13", "9", 
									"1542787200", "3124.60", "3144.37", "3124.60", "3144.36", "0", "0", "223", 
									"1542790800", "3144.36", "3145.60", "3134.06", "3138.18", "0", "0", "218", 
									"1542794400", "3138.19", "3148.22", "3128.99", "3131.11", "0", "0", "224", 
									"1542798000", "3131.11", "3137.16", "3127.16", "3131.37", "0", "0", "218", 
									"1542801600", "3131.38", "3142.15", "3129.36", "3141.27", "0", "0", "210", 
									"1542805200", "3141.27", "3143.85", "3136.37", "3140.03", "0", "0", "211", 
									"1542808800", "3140.03", "3143.74", "3133.66", "3141.54", "0", "0", "225", 
									"1542812400", "3141.54", "3152.21", "3141.54", "3147.17", "0", "0", "222", 
									"1542816000", "3147.18", "3156.77", "3145.27", "3156.77", "0", "0", "108"]
		end 

    it_behaves_like 'HistoricalData message'
		its( :count ){ is_expected.to eq 9 }
		its( :results ){ is_expected.to be_a Array }
		its( :results ){ is_expected.to have(9).bars }

  end


  context 'Message received from IB', :connected => true  do

    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			ib.send_message IB::Messages::Outgoing::RequestHistoricalData.new(
                      :request_id => 123,
                      :contract => IB::Symbols::Index.stoxx,
                      :end_date_time => Time.now.to_ib,
                      :duration => '1 D', #    
                      :bar_size => :hour1, #  IB::BAR_SIZES.key(:hour)?
                      :what_to_show => :trades,
											:use_rth => 0,
											:keep_up_todate => 0,)
      ib.wait_for :HistoricalData
    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:HistoricalData].last }
		 
    it_behaves_like 'HistoricalData message' 


  end #
end # describe IB::Messages:Incoming
