require 'model_helper'
require 'message_helper'

describe IB::Execution,
  :props => {:account_name => "DU111110",
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
             :order_ref => 'Myref',
             :ev_rule => 'aussieBond:YearsToExpiration=3',
             :ev_multiplier => 0.5,
             },

  :human => "<Execution: 20120312  15:41:09 buy 20000 at 1.31075 on IDEALPRO, cumulative 20000 at 1.31075, ids 373/1695693619/0001f4e8.4f5d48f1.01.01>",

  :errors =>  {:side=>["should be buy/sell/short"],
               :cumulative_quantity=>["is not a number"],
               :average_price=>["is not a number"]},

  :assigns => {[:local_id, :perm_id, :client_id, :cumulative_quantity, :price, :average_price] =>
               numeric_assigns,
               :liquidation => boolean_assigns,
               },

  :aliases => {[:side, :action] => buy_sell_assigns,
               [:quantity, :shares] => numeric_assigns,
               [:account_name, :account_number]=> string_assigns,
               },

  :associations => {:order => {:local_id => 23,
                               :perm_id => 173276893,
                               :client_id => 1111,
                               :parent_id => 0,
                               :quantity => 100,
                               :side => :buy,
                               :order_type => :market}
} do

  it_behaves_like 'Model with invalid defaults'
  it_behaves_like 'Self-equal Model'

  context 'DB backed associations', :db => true do
    subject { IB::Execution.new props }

    before(:all) { DatabaseCleaner.clean }

    it 'saves associated order' do
      order = IB::Order.new associations[:order]
      subject.order = order
      expect( subject.order ).to eq order
      expect( subject.order ).to  be_new_record

      subject.save
      expect( subject.order ).not_to be_new_record
      expect( subject.order.executions ).to  include subject
    end

    it 'loads saved association with execution' do
      order = IB::Order.first

      execution = IB::Execution.first

      expect( execution ).to eq subject

      execution.order.should == order
      expect( order.executions.first).to eq execution
    end
  end

  if OPTS[:db]
  context 'extra ActiveModel goodness' , :pending => 'needs further consideration if used anywhere'  do
    subject { IB::Execution.new props }

    it 'correctly serializes Model into hash and json' do
      # p subject.as_json
      {"account_name"=>"DU111110",
       "average_price"=>1.31075,
       "client_id"=>1111,
       "cumulative_quantity"=>20000,
       "exchange"=>"IDEALPRO",
       "exec_id"=>"0001f4e8.4f5d48f1.01.01",
       "id"=>nil,
       "liquidation"=>true,
       "local_id"=>373,
       "order_ref"=>'Myref',
       "ev_rule" => 'aussieBond:YearsToExpiration=3',
       "ev_multiplier" => 0.5,
       "perm_id"=>1695693619,
       "price"=>1.31075,
       "quantity"=>20000,
       "time"=>"20120312  15:41:09",
       "side"=>:buy, }.each do |key, value|

        expect( subject.serializable_hash[key] ).to eq value

        if OPTS[:rails] == "Dummy" # "Dummy" Rails app removes extra key level from json...
          expect( subject.as_json[key] ).to eq value
        else
		## raises Error
          expect( subject.as_json["execution"][key]).to eq value
        end
      end

      expect( subject.to_xml ).to match /<account-name>DU111110<.account-name>\n  <average-price type=\"float\">1.31075<.average-price>\n  <client-id type=\"integer\">1111<.client-id>/

      if OPTS[:rails] == "Dummy" # "Dummy" Rails app removes extra key level from json...
        expect( subject.to_json ).to match /\{\"account_name\":\"DU111110\",\"average_price\":1.31075,\"client_id\":1111,\"/
      else
        expect( subject.to_json ).to match /\{\"execution\":\{\"account_name\":\"DU111110\",\"average_price\":1.31075,\"client_id\":1111,\"/
      end

      expect( IB::Execution.new.from_json(subject.to_json) ).to eq subject
    end
  end
  end

end # describe IB::Execution
