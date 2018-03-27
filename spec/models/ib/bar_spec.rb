require 'model_helper'

describe IB::Bar do
	let(:props ) { 
             {:open => 1.31,
              :high => 1.35,
              :low => 1.30,
              :close => 1.33,
              :wap => 1.32,
              :volume => 20000,
              :has_gaps => true,
              :trades => 50,
              :time => "20120312  15:41:09" } }
#         :human =>
#             "<Bar: 20120312  15:41:09 wap 1.32 OHLC 1.31 1.35 1.3 1.33 trades 50 vol 20000 gaps true>",
#         :errors =>
#             {:close => ["is not a number"],
#              :high => ["is not a number"],
#              :low => ["is not a number"],
#              :open => ["is not a number"],
#              :volume => ["is not a number"]},
#         :assigns =>
#             {:has_gaps => {[1, true] => true, [0, false] => false},
#
#              [:open, :high, :low, :close, :volume] =>
#                  {[:foo, 'BAR', nil] => /is not a number/}
#             } }
#
  it_behaves_like 'Model with invalid defaults'
  it_behaves_like 'Self-equal Model'

end # describe IB::Bar
