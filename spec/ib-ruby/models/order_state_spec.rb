require 'model_helper'

describe IB::Models::OrderState do

  let(:props) do
    {:local_id => 23,
     :perm_id => 173276893,
     :client_id => 1111,
     :parent_id => 0,
     :filled => 3,
     :remaining => 2,
     :last_fill_price => 0.5,
     :average_fill_price => 0.55,
     :why_held => 'child',

     :init_margin => 500.0,
     :maint_margin => 500.0,
     :equity_with_loan => 750.0,
     :commission_currency => 'USD',
     :commission => 1.2,
     :min_commission => 1,
     :max_commission => 1.5,
     :status => 'PreSubmitted',
     :warning_text => 'Oh noes!',
    }
  end

  # TODO: :presents => { Object => "Formatted"}
  let(:human) do
    "<OrderState: PreSubmitted #23/173276893 from 1111 filled 3/2 at 0.5/0.55 margin 500.0/500.0 equity 750.0 fee 1.2 why_held child warning Oh noes!>"
  end

  let(:defaults) do
    {
        #:created_at => Time,   # Does not work in DB mode
    }
  end

  let(:errors) do
    {:status => ["must not be empty"],
    }
  end

  let(:assigns) do
    {[:status] =>
         {[nil, ''] => /must not be empty/,
          ['Zorro', :Zorro] => 'Zorro' }
    }
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

end # describe IB::Order
