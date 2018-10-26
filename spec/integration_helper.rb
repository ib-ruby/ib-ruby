require 'message_helper'
require 'account_helper'

RSpec.shared_examples_for 'Received Market Data' do  | request_id |
  context IB::Messages::Incoming::Alert  do
    subject { IB::Connection.current.received[:Alert].first }

    it { is_expected.to be_an IB::Messages::Incoming::Alert }
    it { is_expected.to be_warning }
    it { is_expected.not_to be_error }
    its(:code) { is_expected.to be_an Integer }
    its(:message) { is_expected.to match /data farm connection is OK/ }
    its(:to_human) { is_expected.to match /TWS Warning/ }
  end

  context IB::Messages::Incoming::TickPrice  do
    subject { IB::Connection.current.received[:TickPrice].first }

    it { is_expected.to be_an IB::Messages::Incoming::TickPrice }
    its(:tick_type) { is_expected.to be_an Integer }
    its(:type) { is_expected.to be_a Symbol }
    its(:price) { is_expected.to be_a BigDecimal }
    its(:size) { is_expected.to be_an Integer }
    its(:data) { is_expected.to be_a Hash }
    its(:ticker_id) { is_expected.to eq request_id } # ticker_id
    its(:to_human) { is_expected.to match /TickPrice/ }
  end

  context IB::Messages::Incoming::TickSize do
    subject { IB::Connection.current.received[:TickSize].first }

    it { is_expected.to be_an IB::Messages::Incoming::TickSize }
    its(:type) { is_expected.to_not be_nil }
    its(:data) { is_expected.to be_a Hash }
    its(:tick_type) { is_expected.to be_an Integer }
    its(:type) { is_expected.to be_a Symbol }
    its(:size) { is_expected.to be_an Integer }
    its(:ticker_id) { is_expected.to eq request_id }
    its(:to_human) { is_expected.to match /TickSize/ }
  end
end
