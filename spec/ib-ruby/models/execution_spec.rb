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

  let(:errors) do
    {:side=>["should be buy/sell/short"],
     :cumulative_quantity=>["is not a number"],
     :average_price=>["is not a number"]}
  end

  let(:assigns) do
    {[:perm_id, :client_id, :cumulative_quantity, :price, :average_price] => numeric_assigns,
     :liquidation => boolean_assigns,
    }
  end

  let(:aliases) do
    {[:side, :action] => buy_sell_assigns,
     [:local_id, :order_id] => numeric_assigns,
     [:quantity, :shares] => numeric_assigns,
     [:account_name, :account_number]=> string_assigns,
    }
  end

  let(:associations) do
    {:order => IB::Order.new(:local_id => 23,
                             :perm_id => 173276893,
                             :client_id => 1111,
                             :parent_id => 0,
                             :quantity => 100,
                             :order_type => :market)
    }
  end

  it_behaves_like 'Model'

  ## TODO: Playing with associations!
  context 'associations' do
    subject { IB::Execution.new props }

    before(:all) { DatabaseCleaner.clean if IB::DB }

    it 'saves associated order' do
      order = associations[:order]

      #p order.save

      subject.order = order

      p subject.save
      p subject.errors.messages


      p subject.order
      p subject.order.executions
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
      #p s1.order.executions

      #p o1 = IB::Order.find(:first)
      #p o1.execution
      #
      #p o1.execution.order_id
    end

  end

end # describe IB::Models::Contract
