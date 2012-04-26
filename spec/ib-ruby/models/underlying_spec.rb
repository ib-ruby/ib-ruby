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

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context 'using shortest class name without properties' do
    subject { IB::Underlying.new }
    it_behaves_like 'Model instantiated empty'
    it_behaves_like 'Self-equal Model'
  end

end # describe IB::Contract
