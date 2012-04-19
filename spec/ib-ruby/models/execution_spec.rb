require 'model_helper'

describe IB::Models::Execution do # AKA IB::Execution

  let(:props) do
    {:account_name => "DU111110",
     :client_id => 1111,
     :exchange => "IDEALPRO",
     :exec_id => "0001f4e8.4f5d48f1.01.01",
     :liquidation => true,
     :local_id => 373,
     :perm_id => 1695693619,
     :price => 1.31075,
     :average_price => 1.31075,
     :shares => 20000,
     :cumulative_quantity => 20000,
     :side => :buy,
     :time => "20120312  15:41:09",
    }
  end

  let(:human) do
    "<Execution: 20120312  15:41:09 buy 20000 at 1.31075 on IDEALPRO, " +
        "cumulative 20000 at 1.31075, ids 373/1695693619/0001f4e8.4f5d48f1.01.01>"
  end

  let(:defaults) do
    {:local_id => 0,
     :client_id => 0,
     :perm_id => 0,
     :shares=> 0,
     :price => 0,
     :liquidation => false,
     #:created_at => Time,   # Does not work in DB mode
    }
  end

  let(:errors) do
    {:side=>["should be buy/sell/short"],
     :cumulative_quantity=>["is not a number"],
     :average_price=>["is not a number"]}
  end

  let(:assigns) do
    {:side =>
         {['BOT', 'BUY', 'Buy', 'buy', :BUY, :BOT, :Buy, :buy, 'B', :b] => :buy,
          ['SELL', 'SLD', 'Sel', 'sell', :SELL, :SLD, :Sell, :sell, 'S', :S] => :sell},

     [:local_id, :perm_id, :client_id] =>
         {1313 => 1313,
          [:foo, 'BAR', nil] => /is not a number/},

     [:shares, :cumulative_quantity, :price, :average_price] =>
         {[:foo, 'BAR', nil] => /is not a number/},

     :liquidation => {[1, true] => true, [0, false] => false},
    }
  end

  it_behaves_like 'Model'

  it 'has legacy :local_id accessor, aliasing :local_id' do
    subject.order_id = 131313
    subject.local_id.should == 131313
    subject.local_id = 111111
    subject.order_id.should == 111111
  end

  ## TODO: Playing with associations!

  let(:association) do
    IB::OrderState.new :local_id => 23,
                       :perm_id => 173276893,
                       :client_id => 1111,
                       :parent_id => 0,
                       :filled => 3,
                       :remaining => 2,
                       :last_fill_price => 0.5,
                       :average_fill_price => 0.55,
                       :why_held => 'child'

  end

  context 'associations' do
    subject { IB::Execution.new props }

    before(:all) { DatabaseCleaner.clean if IB::DB }

    it 'saves associated bar' do
      os = association

      #p bar.save

      subject.order_state = os

      p subject.save
      p subject.errors.messages


      p subject.order_state
      p subject.order_state.execution
      p subject.to_xml
      p subject.serializable_hash
      p subject.to_json
      p subject.as_json

      p IB::Execution.new.from_json subject.to_json # TODO: Strings for keys!

      pending 'Still need to test associations properly'
    end

    it 'loads associated execution' do
      pending 'Still need to test associations properly'

      #s1 = IB::Execution.first
      #p s1
      #p s1.bar.execution

      #p b1 = IB::Bar.find(:first)
      #p b1.execution
      #
      #p b1.execution.bar_id
    end

  end

end # describe IB::Models::Contract
