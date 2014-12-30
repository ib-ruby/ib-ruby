require 'model_helper'
require 'message_helper'

describe IB::OrderState,
         :props =>
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
             },
         :human =>
             "<OrderState: PreSubmitted #23/173276893 from 1111 filled 3/2 at 0.5/0.55 margin 500.0/500.0 equity 750.0 fee 1.2 why_held child warning Oh noes!>",
         :errors =>
             {:status => ["must not be empty"],
             },
         :assigns =>
             {[:status] =>
                  {[nil, ''] => /must not be empty/,
                   ['Zorro', :Zorro] => 'Zorro'},

              :local_id => numeric_or_nil_assigns,
             },
         :aliases =>
             {[:price, :last_fill_price] => float_or_nil_assigns,
              [:average_price, :average_fill_price] => float_or_nil_assigns,
             } do

  it_behaves_like 'Self-equal Model'
  it_behaves_like 'Model with invalid defaults'

  context '#update_missing' do
    let(:nil_state) { IB::OrderState.new(:filled => nil, :remaining => nil,
                                         :price => nil, :average_price => nil) }
    context 'updating with Hash'  do
      subject { nil_state.update_missing(props) }
      it_behaves_like 'Model instantiated with properties'
    end

    context 'updating with Model' do
      subject { nil_state.update_missing(IB::OrderState.new(props)) }
      it_behaves_like 'Model instantiated with properties'
    end
  end

  it 'has extra test methods'  do  # passes 301214
    empty_state = IB::OrderState.new
    expect( empty_state ).to be_new
     expect( subject ).not_to be_pending
     expect( subject ).not_to  be_submitted
     expect( empty_state ).to be_active
     expect( empty_state ).not_to be_inactive
     expect( empty_state ).not_to be_complete_fill

    state = IB::OrderState.new(props)
    ['PendingSubmit', 'PreSubmitted', 'Submitted'].each do |status|
      state.status = status
      expect( state ).not_to be_new
      expect( state ).to be_active
      expect( state ).not_to be_inactive
      expect( state ).not_to be_complete_fill
      expect( state ).to be_pending
     if status == 'PendingSubmit' 
	expect( state ).not_to  be_submitted
     else
     	expect( state ).to be_submitted
     end
    end

    ['PendingCancel', 'Cancelled', 'ApiCancelled', 'Inactive'].each do |status|
      state.status = status
      expect( state ).not_to be_new
      expect( state ).not_to be_active
      expect( state ).to be_inactive
      expect( state ).not_to be_complete_fill
      expect( state ).not_to be_pending
      expect( subject ).not_to be_submitted
    end

    state.status = 'Filled'
      expect( state ).not_to be_new
      expect( state ).not_to be_active
      expect( state ).to be_inactive
      expect( state ).not_to be_complete_fill
      expect( state ).not_to be_pending
      expect( subject ).not_to be_submitted

    state.remaining = 0
      expect( state ).not_to be_new
      expect( state ).not_to be_active
      expect( state ).to be_inactive
      expect( state ).to be_complete_fill
      expect( state ).not_to be_pending
      expect( subject ).not_to be_submitted
  end

end # describe IB::OrderState
