require 'model_helper'

describe IB::Models::Underlying,
         :props =>
             {:con_id => 234567,
              :delta => 0.55,
              :price => 20.5,
             },

         :human => /<Underlying: con_id: 234567 .*delta: 0.55 price: 20.5.*>/,

         :errors =>
             {:delta => ['is not a number'],
              :price => ['is not a number'],
             },

         :assigns =>
             {[:con_id, :delta, :price] => numeric_assigns,

             } do # AKA IB::Underlying

  it_behaves_like 'Self-equal Model'
  it_behaves_like 'Model with invalid defaults'

  it 'has class name shortcut' do
    IB::Underlying.should == IB::Models::Underlying
    IB::Underlying.new.should == IB::Models::Underlying.new
  end
end # describe IB::Contract
