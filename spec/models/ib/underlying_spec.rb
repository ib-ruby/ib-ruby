require 'model_helper'

describe IB::Underlying,
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

             } do

  it_behaves_like 'Self-equal Model'
  it_behaves_like 'Model with invalid defaults'

end # describe IB::ib/
