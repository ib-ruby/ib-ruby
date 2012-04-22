require 'model_helper'

describe IB::Models::ContractDetail do # AKA IB::ContractDetail

  let(:props) do
    {:market_name => 'AAPL',
     :trading_class => 'AAPL',
     :min_tick => 0.01,
     :price_magnifier => 1,
     :order_types => 'ACTIVETIM,ADJUST,ALERT,ALGO,ALLOC,AON,AVGCOST,BASKET,COND,CONDORDER,DAY,DEACT,DEACTDIS,DEACTEOD,FOK,GAT,GTC,GTD,GTT,HID,ICE,IOC,LIT,LMT,MIT,MKT,MTL,NONALGO,OCA,PAON,POSTONLY,RELSTK,SCALE,SCALERST,SMARTSTG,STP,STPLMT,TRAIL,TRAILLIT,TRAILLMT,TRAILMIT,VOLAT,WHATIF,',
     :valid_exchanges => 'SMART,AMEX,BATS,BOX,CBOE,CBOE2,IBSX,ISE,MIBSX,NASDAQOM,PHLX,PSE', #   The list of exchanges this contract is traded on.
     :under_con_id => 265598,
     :long_name => 'APPLE INC',
     :contract_month => '201301',
     :industry => 'Technology',
     :category => 'Computers',
     :subcategory => 'Computers',
     :time_zone => 'EST',
     :trading_hours => '20120422:0930-1600;20120423:0930-1600',
     :liquid_hours => '20120422:0930-1600;20120423:0930-1600',
    }
  end

  let(:human) do
    "<ContractDetail: coupon: 0 under_con_id: 265598 min_tick: 0.01 callable: false puttable: false convertible: false next_option_partial: false market_name: AAPL trading_class: AAPL price_magnifier: 1 order_types: ACTIVETIM,ADJUST,ALERT,ALGO,ALLOC,AON,AVGCOST,BASKET,COND,CONDORDER,DAY,DEACT,DEACTDIS,DEACTEOD,FOK,GAT,GTC,GTD,GTT,HID,ICE,IOC,LIT,LMT,MIT,MKT,MTL,NONALGO,OCA,PAON,POSTONLY,RELSTK,SCALE,SCALERST,SMARTSTG,STP,STPLMT,TRAIL,TRAILLIT,TRAILLMT,TRAILMIT,VOLAT,WHATIF, valid_exchanges: SMART,AMEX,BATS,BOX,CBOE,CBOE2,IBSX,ISE,MIBSX,NASDAQOM,PHLX,PSE long_name: APPLE INC contract_month: 201301 industry: Technology category: Computers subcategory: Computers time_zone: EST trading_hours: 20120422:0930-1600;20120423:0930-1600 liquid_hours: 20120422:0930-1600;20120423:0930-1600>"
  end

  let(:errors) do
    {:time_zone => ['should be XXX'],
    }
  end

  let(:assigns) do
    {[:under_con_id, :min_tick, :coupon] => {123 => 123},

     [:callable, :puttable, :convertible, :next_option_partial] => boolean_assigns,
    }
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context 'using shortest class name without properties' do
    subject { IB::ContractDetail.new }
    it_behaves_like 'Model instantiated empty'
    it_behaves_like 'Self-equal Model'
  end

end # describe IB::Contract
