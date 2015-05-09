### needs cleaning ####
require 'message_helper'
require 'account_helper'
require 'connection_helper'

describe IB::Connection do
 
  # Expose protected methods as public methods.
  before(:each){ IB::Connection.send(:public, *IB::Connection.protected_instance_methods)  }

  before(:all){ verify_account }
  after(:all){ IB::Gateway.current.disconnect } 

###<<<<<<< HEAD  -- to be checked
  context 'instantiated and connected' , focus: true do
    subject {IB::Gateway.tws }
    it_behaves_like 'Connected Connection without receiver' 
  end

  context 'connected and operable' , focus:true do
    before(:all) { IB::Gateway.tws.wait_for :NextValidId, 2 }
    subject {IB::Gateway.tws }
    it_behaves_like 'Connected Connection' 
  end
###=======
  it 'keeps received messages in Hash by default' do
    expect(subject.received).to be_a Hash
  end

  it 'has received a :NextValidId' do
    expect(subject.received[:NextValidId]).not_to be_empty
  end

end

shared_examples_for 'Connected Connection without receiver' do

  it { should_not be_nil }
  it { should be_connected }
  its(:reader) { should be_a Thread }
  its(:server_version) { should be_an Integer }
  its(:client_version) { should be_an Integer }
  its(:subscribers) { is_expected.not_to be_empty } # :NextValidId and empty Hashes
  its(:next_local_id) { should be_a Fixnum } # Not before :NextValidId arrives
end

# Need top level method to access instance var (@received) in nested context
def create_connection opts={}
  # Start disconnected (we need to set up catch-all subscriber first)
  @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger).merge(opts)

  # Hash of received messages, keyed by message type
  @received = Hash.new { |hash, key| hash[key] = Array.new }

  #@alert = @ib.subscribe(:Alert) { |msg| puts msg.to_human }

  @subscriber = proc { |msg| @received[msg.message_type] << msg }
end
###>>>>>>> upstream/gateway


  describe '#send_message', 'sending messages' , focus:true  do
    it 'allows 3 signatures representing IB::Messages::Outgoing'  do
      expect { IB::Gateway.current.send_message :RequestOpenOrders }.to_not raise_error
      expect { IB::Gateway.current.send_message IB::Messages::Outgoing::RequestOpenOrders }.to_not raise_error
      expect { IB::Gateway.current.send_message IB::Messages::Outgoing::RequestOpenOrders.new }.to_not raise_error
    end

    it 'has legacy #dispatch alias'do
      expect { IB::Gateway.tws.dispatch :RequestOpenOrders }.to_not raise_error
    end
  end

  let( :subscriber ) { Proc.new {} }
  let( :subscriber_id ) do
    ib = IB::Gateway.tws
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
	ib = IB::Gateway.tws
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

##<<<<<<< HEAD
##=======
      describe '#subscribe' do
        after(:all) { clean_connection }

        it 'adds (multiple) subscribers, returning subscription id' do
          @id[:first] = @ib.subscribe(IB::Messages::Incoming::OrderStatus) do |msg|
            log msg.to_human
          end

          @id[:second] = @ib.subscribe /Value/, :OpenOrder, @subscriber

          @id[:third] = @ib.subscribe /Account/, &@subscriber

          [[@id[:first], IB::Messages::Incoming::OrderStatus],
           [@id[:second], IB::Messages::Incoming::OpenOrder],
           [@id[:second], IB::Messages::Incoming::PortfolioValue],
           [@id[:second], IB::Messages::Incoming::AccountValue], # as /Value/
           [@id[:third], IB::Messages::Incoming::AccountValue], #  as /Account/
           [@id[:third], IB::Messages::Incoming::AccountDownloadEnd],
           [@id[:third], IB::Messages::Incoming::AccountUpdateTime],
          ].each do |(subscriber_id, message_class)|
            expect(@ib.subscribers).to have_key(message_class)
            expect(@ib.subscribers[message_class]).to have_key(subscriber_id)
          end
        end

        it 'returns Integer subscription id' do
          expect(@id[:first]).to be_an Integer
          expect(@id[:second]).to be_an Integer
          expect(@id[:third]).to be_an Integer
        end

        context 'when subscribed' do

          before(:all) do
            @ib.send_message :RequestAccountData
            @ib.wait_for :AccountDownloadEnd, 3
          end

          after(:all) { @ib.send_message :RequestAccountData, :subscribe => false }

          it 'receives subscribed message types and processes them in subscriber callback' do
            print "Sad API Warning for new accounts PortfolioValue can be empty causing a series of spec errors."
            expect(@received[:AccountValue]).not_to be_empty
            expect(@received[:PortfolioValue]).not_to be_empty
            expect(@received[:AccountDownloadEnd]).not_to be_empty
            expect(@received[:AccountUpdateTime]).not_to be_empty
          end

          it_behaves_like 'Valid account data request'
        end
      end # subscribe

      describe '#unsubscribe' do
        before(:all) { @result = @ib.unsubscribe @id[:first], @id[:second] }

        it 'removes all subscribers at given id or ids' do
          [IB::Messages::Incoming::OrderStatus,
           IB::Messages::Incoming::OpenOrder,
           IB::Messages::Incoming::PortfolioValue,
           IB::Messages::Incoming::AccountValue,
          ].each do |message_class|
            expect(@ib.subscribers[message_class]).not_to have_key(@id[:first])
            expect(@ib.subscribers[message_class]).not_to have_key(@id[:second])
          end
        end

        it 'does not remove subscribers at other ids' do
          expect(@ib.subscribers[IB::Messages::Incoming::AccountValue]).to have_key(@id[:third])
          expect(@ib.subscribers[IB::Messages::Incoming::AccountDownloadEnd]).to have_key(@id[:third])
          expect(@ib.subscribers[IB::Messages::Incoming::AccountUpdateTime]).to have_key(@id[:third])
        end

        it 'returns an Array of removed subscribers' do
          expect(@result).to be_an Array
          expect(@result.size).to eq(4)
        end

        it 'raises on nosense id given' do
          expect { @ib.unsubscribe 'nonsense' }.to raise_error /No subscribers with id/
          expect { @ib.unsubscribe rand(9999999) }.to raise_error /No subscribers with id/
        end
      end
###>>>>>>> upstream/gateway

	## subscriber_id's	
	it{ subscriber_id.values.each{ |v| expect(v).to be_an Integer }}

	it "unsubscribe from Message-Classes" do
	  IB::Gateway.tws.subscribers.keys.each do |message|
	    imio = IB::Gateway.tws.subscribers[message]
	    unless imio.empty?
	    expect( imio ).to have_at_least(1).items
	    imio.keys.each do |y|
	      IB::Gateway.tws.unsubscribe y
	    end
	    expect( imio ).to be_empty
	    end
	  end
	end
    end # describe
    context 'when subscribed' , focus:true do

      before(:all) do
	## if the advisor-account is used here, the test fails because PortfolioValueData are missing
	IB::Gateway.current.send_message :RequestAccountData,  :account_code => OPTS[:connection][:user]
	IB::Gateway.tws.wait_for :AccountDownloadEnd, 3
      end

      after(:all) { IB::Gateway.current.send_message :RequestAccountData, :subscribe => false }

###<<<<<<< HEAD
      it 'receives subscribed message types and processes them in subscriber callback' do
	[:AccountValue, :PortfolioValue, :AccountDownloadEnd, :AccountUpdateTime].each do |x|
	  expect( IB::Gateway.tws.received[ x ] ).not_to be_empty
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
###=======
        it 'receives subscribed message types still subscribed' do
          expect(@received[:AccountValue]).not_to be_empty
          expect(@received[:AccountUpdateTime]).not_to be_empty
          expect(@received[:AccountDownloadEnd]).not_to be_empty
        end

        it 'does not receive unsubscribed message types' do
          expect(@received[:PortfolioValue]).to be_empty
        end

        # this orginally tested for a lack of subscriber for PortfolioValue message which does not see to exist
        it { log_entries.any? { |entry| expect(entry).to match(/No subscribers for message .*:Alert!/) }}
        it { log_entries.any? { |entry| expect(entry).not_to match(/No subscribers for message .*:AccountValue/) }}
      end # when subscribed
    end # subscriptions
###>>>>>>> upstream/gateway

    it 'returns empty array if nonsence is provided', focus:true do
      expect( IB::Gateway.current.unsubscribe 'nonsense' ).to be_empty
      expect( IB::Gateway.current.unsubscribe rand(9999999)).to be_empty
    end
    it 'removes all subscribers at given id or ids'  do
      messages.each do |message_class|
	  puts "Message_class"
	  puts message_class.inspect
  	 puts IB::Gateway.tws.subscribers[message_class].inspect
	[:first,:second].each do |key|
	  expect(IB::Gateway.tws.subscribers[message_class]).not_to have_key( subscriber_id[ key ] )
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
