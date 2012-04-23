require 'model_helper'

describe IB::Models::Underlying do # AKA IB::Underlying

  let(:props) do
    {:con_id => 234567,
     :delta => 0.55,
     :price => 20.5,
    }
  end

  let(:human) do
    /<Underlying: con_id: 234567 .*delta: 0.55 price: 20.5.*>/
  end

  let(:errors) do
    {:delta => ['is not a number'],
     :price => ['is not a number'],
    }
  end

  let(:assigns) do
    {[:con_id, :delta, :price] => numeric_assigns,
    }
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context 'using shortest class name without properties' do
    subject { IB::Underlying.new }
    it_behaves_like 'Model instantiated empty'
    it_behaves_like 'Self-equal Model'
  end

end # describe IB::Contract
