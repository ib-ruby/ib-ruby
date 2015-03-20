### needs cleaning ####
require 'message_helper'
require 'account_helper'
require 'connection_helper'

describe IB::Connection do
 
  # Expose protected methods as public methods.
  before(:each){ IB::Connection.send(:public, *IB::Connection.protected_instance_methods)  }

  before(:all){ IB::Connection.new port:7496, logger: mock_logger }
  after(:all){ IB::Connection.current.disconnect } 

  context 'instantiated and connected' , focus: true do
    subject {IB::Connection.current }
    it_behaves_like 'Connected Connection without receiver' 
  end

  context 'connected and operable' , focus:true do
    before(:all) { IB::Connection.current.wait_for :NextValidId, 2 }
    subject { IB::Connection.current }
    it_behaves_like 'Connected Connection' 
  end


  describe '#send_message', 'sending messages' , focus:true  do
    it 'allows 3 signatures representing IB::Messages::Outgoing'  do
      expect { IB::Connection.current.send_message :RequestOpenOrders }.to_not raise_error
      expect { IB::Connection.current.send_message IB::Messages::Outgoing::RequestOpenOrders }.to_not raise_error
      expect { IB::Connection.current.send_message IB::Messages::Outgoing::RequestOpenOrders.new }.to_not raise_error
    end

    it 'has legacy #dispatch alias'do
      expect { IB::Connection.current.dispatch :RequestOpenOrders }.to_not raise_error
    end
  end

  let( :subscriber ) { Proc.new {} }
  let( :subscriber_id ) do
    ib = IB::Connection.current
    {  first: ib.subscribe(IB::Messages::Incoming::OrderStatus) do |msg|
      log msg.to_human
    end ,
    second: ib.subscribe( /Value/, :OpenOrder, subscriber),
    third:  ib.subscribe( /Account/, &subscriber) 
    }
  end
  context "subscriptions" do
    describe '#subscribe', focus:true  do

      it 'adds (multiple) subscribers, returning subscription id' do
	ib = IB::Connection.current
	[[ subscriber_id[:first], IB::Messages::Incoming::OrderStatus ],
  [ subscriber_id[ :second], IB::Messages::Incoming::OpenOrder  ],
  [ subscriber_id[ :second], IB::Messages::Incoming::PortfolioValue ],
  [ subscriber_id[ :second], IB::Messages::Incoming::AccountValue ], # as /Value/
  [ subscriber_id[ :third ], IB::Messages::Incoming::AccountValue ], #  as /Account/
  [ subscriber_id[ :third ], IB::Messages::Incoming::AccountDownloadEnd ],
  [ subscriber_id[ :third ], IB::Messages::Incoming::AccountUpdateTime ],
	].each do |(subscriber_id, message_class)|
	  expect( ib.subscribers).to have_key(message_class)
	  expect( ib.subscribers[message_class]).to have_key(subscriber_id)
	end
      end


	## subscriber_id's	
	it{ subscriber_id.values.each{ |v| expect(v).to be_an Integer }}

	it "unsubscribe from Message-Classes" do
	  IB::Connection.current.subscribers.keys.each do |message|
	    imio = IB::Connection.current.subscribers[message]
	    unless imio.empty?
	    expect( imio ).to have_at_least(1).items
	    imio.keys.each do |y|
	      IB::Connection.current.unsubscribe y
	    end
	    expect( imio ).to be_empty
	    end
	  end
	end
    end # describe
    context 'when subscribed' , focus:true do

      before(:all) do
	## if the advisor-account is used here, the test fails because PortfolioValueData are missing
	IB::Connection.current.send_message :RequestAccountData,  :account_code => OPTS[:connection][:user]
	IB::Connection.current.wait_for :AccountDownloadEnd, 3
      end

      after(:all) { IB::Connection.current.send_message :RequestAccountData, :subscribe => false }

      it 'receives subscribed message types and processes them in subscriber callback' do
	[:AccountValue, :PortfolioValue, :AccountDownloadEnd, :AccountUpdateTime].each do |x|
	  expect( IB::Connection.current.received[ x ] ).not_to be_empty
	end
      end

      it_behaves_like 'Valid account data request'
    end  # context 'when subscribed'
  end # describe #subscribe 
	#
  describe '#unsubscribe' do

    let( :messages ){[IB::Messages::Incoming::OrderStatus,
		      IB::Messages::Incoming::OpenOrder,
		      IB::Messages::Incoming::PortfolioValue,
		      IB::Messages::Incoming::AccountValue ]  }

    it 'returns empty array if nonsence is provided', focus:true do
      expect( IB::Connection.current.unsubscribe 'nonsense' ).to be_empty
      expect( IB::Connection.current.unsubscribe rand(9999999)).to be_empty
    end
    it 'removes all subscribers at given id or ids'  do
      messages.each do |message_class|
	  puts "Message_class"
	  puts message_class.inspect
  	 puts IB::Connection.current.subscribers[message_class].inspect
	[:first,:second].each do |key|
	  expect(IB::Connection.current.subscribers[message_class]).not_to have_key( subscriber_id[ key ] )
	end
      end
    end



  end

#	context 'when unsubscribed' do
#
#	  before(:all) do
#	    @ib.send_message :RequestAccountData
#	    @ib.wait_for { !@ib.received[:AccountDownloadEnd].empty? }
#	  end
#
#	  after(:all) { @ib.send_message :RequestAccountData, :subscribe => false }
#
#	  it 'receives subscribed message types still subscribed' do
#	    [:AccountValue,	:AccountUpdateTime, :AccountDownloadEnd].each do  |sy|
#	      expect( @ib.received[sy]).not_to be_empty
#	    end
#	  end
#
#	  #        it 'does not receive unsubscribed message types' do
#	  #         @ib.received[:PortfolioValue].should be_empty
#	  #       end
#
#	  it { should_log /No subscribers for message .*:PortfolioValue/ }
#	  it { should_not_log /No subscribers for message .*:AccountValue/ }
#	end # when subscribed
end # describe IB::Connection
