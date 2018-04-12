require 'order_helper'
require 'spec_helper'

shared_examples_for 'OrderStatus message' do
  it { should be_an IB::Messages::Incoming::OrderStatus }
  its( :message_type){ is_expected.to eq :OrderStatus }
  its( :message_id ) { is_expected.to eq 3 }
  its( :data )       { is_expected.not_to  be_empty }
  its( :buffer )     { is_expected.to be_empty }  # Work on openOrder-Message has to be finished.
  its( :local_id )   { is_expected.to be_an Integer }
  its( :status )     { is_expected.to match  /Submit/ }
  its( :to_human )   { is_expected.to match /<OrderStatus: <OrderState: .*Submit.* #\d+\/\d+ from 1111 filled 0.0\/100/ }

  it 'has proper order_state accessor' do
    os = subject.order_state
    expect(  os.local_id ).to  be_an Integer
    expect(  os.perm_id  ).to  be_an Integer
    expect(  os.client_id).to eq  1111
    expect(  os.parent_id).to be_zero
    expect(  os.filled   ).to be_zero
    expect(  os.remaining).to eq 100
    expect(  os.average_fill_price).to be_zero
    expect(  os.last_fill_price).to be_zero
    expect(  os.status   ).to match /Submit/
    expect(  os.why_held ).to match  /child|/
  end

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 3
    expect( subject.class.version).to be_zero
		expect( subject.class.message_type).to eq :OrderStatus
  end

end

describe IB::Messages::Incoming::OrderStatus   do

	context 'Instantiated with raw data' do
		subject do
			IB::Messages::Incoming::OrderStatus.new [
				"3", "Submitted", "0", "100", "0", "2044311842", "0", "0", "1111", "", "0"		  ]

		end
			it_behaves_like 'OrderStatus message'
	end
  context 'Instantiated with data Hash' do
    subject do
      IB::Messages::Incoming::OrderStatus.new :version => 0,
        :order_state => { :local_id => 1313,
                          :perm_id => 172323928,
                          :client_id => 1111,
                          :parent_id => 0,
                          :status => 'PreSubmitted',
                          :filled => 0.0,
                          :remaining => 100,
                          :average_fill_price => 0.0,
                          :last_fill_price => 0.0,
                          :why_held => 'child' }
        end

    it_behaves_like 'OrderStatus message'
  end
# is simulated in first context
#  context 'received from IB' do
#    before(:all) do
#      verify_account
#      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
#   #  @ib.wait_for :NextValidId, 3
#      @local_id = @ib.next_local_id
#      place_order IB::Symbols::Stocks[:wfc]
#      @ib.wait_for 2 # OrderStatus for cancelled orders from previous specs arrives first :(
#    end
#
#    after(:all) { close_connection } # implicitly cancels order
#
#    subject { @ib.received[:OrderStatus].find { |msg| msg.local_id == @local_id } }
#
#    it_behaves_like 'OrderStatus message'
#  end

end # describe IB::Messages:Incoming
