require 'integration_helper'

RSpec.shared_examples 'option_chain' do

		it "values point to Options with different Expiries"	 do
		  subject.values.each do | v |
				expect( v ).to be_an Array
				v.each{| c | expect(c).to be_a IB::Option }
				expiries =  v.map( &:last_trading_day).to_enum
				# first element is min, last element is max
				expect( expiries.minmax ).to eq [expiries.entries.first, expiries.entries.last]
				min =  expiries.next
				# test monoton steigende sortierung
				while min.present?  do
					max= expiries.next  rescue break
					expect(min).to be < max
					min =  max
				end
			end	 # values
		end # it
end
RSpec.shared_examples 'otm/itm_chain' do

		it "has numeric keys" do
		# size = count + atm-option
			expect( subject.keys.size ).to eq 7
			subject.keys.each{ |y| expect(y).to be_a BigDecimal }
		end
 end

RSpec.describe 'IB::Contract.option_chain' , #:if => :us_trading_hours,
         :connected => true, :integration => true  do

  before(:all) do
    verify_account
    IB::Connection.new OPTS[:connection].merge(:logger => mock_logger) do |gw|
			gw.subscribe( :Alert ){|y|  puts y.to_human }
		end
  end

  after(:all) do
    close_connection
  end

	let( :wfc ){ IB::Symbols::Stocks.wfc }

	context "verify" do
		it "is verified" do
			wfc.verify!
			expect(wfc.con_id).not_to be_zero
		end
	end
  context 'read complete Option chain' do

   subject{ IB::Symbols::Stocks.wfc.option_chain( ref_price: 30 ) }

    it {is_expected.to be_a Hash }
		it "has numeric keys" do
			expect( subject.keys.size ).not_to be_zero
			subject.keys.each{ |y| expect(y).to be_a BigDecimal }
		end

		it_behaves_like 'option_chain'
  end   # context

	context  'itm put options'  do
   subject{ IB::Symbols::Stocks.wfc.itm_options( right: :put, ref_price: 40, count: 6) }
		it_behaves_like 'option_chain'
		it_behaves_like 'otm/itm_chain'
	end
	context  'otm put options'  do
   subject{ IB::Symbols::Stocks.wfc.otm_options( right: :put, ref_price: 40, count: 6) }
		it_behaves_like 'option_chain'
		it_behaves_like 'otm/itm_chain'
	end
	context  'itm call options'  do
   subject{ IB::Symbols::Stocks.wfc.itm_options( right: :call, ref_price: 40, count: 6) }
		it_behaves_like 'option_chain'
		it_behaves_like 'otm/itm_chain'
	end
	context  'otm call options'  do
   subject{ IB::Symbols::Stocks.wfc.otm_options( right: :call, ref_price: 40, count: 6) }
		it_behaves_like 'option_chain'
		it_behaves_like 'otm/itm_chain'
	end

	context  'itm put options sorted by expiry'  do
   subject{ IB::Symbols::Stocks.wfc.itm_options( right: :put, ref_price: 40, count: 6, sort: :expiry) }
		it "has numeric keys" do
			subject.keys.each{ |y| expect(y).to be_a Integer }
		end
		it "has appropiate strikes assigned to each expiry" do
		# size = count + atm-option
			subject.values.each { | expiry |  expect(expiry.size).to eq 7 }
		end
	end
end # Request Options Market Data
