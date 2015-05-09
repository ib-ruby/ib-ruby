require 'model_helper'
require 'message_helper'
## no tws-connection required
describe IB::Option,
         :human => "<Option: AAPL 201301 put 600.5 SMART >",

         :errors => {:right => ["should be put or call"],
                     :strike => ["must be greater than 0"],
         },

         :props => {:symbol => 'AAPL',
                    :expiry => '201301',
                    :strike => 600.5,
                    :exchange => 'SMART',
                    :right => :put,
         },

         :assigns => {
             :local_symbol =>
                 {['AAPL  130119C00500000',
                   :'AAPL  130119C00500000'] => 'AAPL  130119C00500000',
                  'BAR'=> /invalid OSI code/},

             :expiry =>
                 {[200609, '200609'] => '200609',
                  [20060913, '20060913'] => '20060913',
                  [:foo, 2006, 42, 'bar'] => /should be YYYYMM or YYYYMMDD/},

             :sec_type =>
                 {['OPT', :option] => :option,
                  IB::CODES[:sec_type].reject { |k, _| k == :option }.to_a =>
                      /should be an option/},

             :right =>
                 {["PUT", "put", "P", "p", :put] => :put,
                  ["CALL", "call", "C", "c", :call] => :call,
                  ['', '0', '?', :none, :foo, 'BAR', 42] => /should be put or call/},

             :exchange => string_upcase_assigns.merge(
                 [:smart, 'SMART', 'smArt'] => 'SMART'),

             :primary_exchange =>string_upcase_assigns.merge(
                 [:SMART, 'SMART'] => /should not be SMART/),

             :multiplier => to_i_assigns,

             :symbol => string_assigns,

             :strike => {[0, -30.0] => /must be greater than 0/},
         } do # AKA IB::Option

	it_behaves_like 'Model with invalid defaults'

	context  FactoryGirl.build( :default_option ).query_contract  do
		#					   it_behaves_like 'Self-equal Model'
		it_behaves_like 'Contract'

		it 'has extra osi accessor, aliasing :local_symbol' do
			expect { subject.osi= 'FOO' }.to change {subject.local_symbol }.from( '' ).to( "FOO" )
			expect( subject).not_to be_valid
		end
		it 'correctly validates OSI symbol' do
			subject.osi= "AAPL  130119C00500000"

			expect( subject.local_symbol).to eq "AAPL  130119C00500000"
			expect( subject).to be_valid
		end
	end

	it 'correctly defines Contract type (sec_type) for Option contract'   do
		[FactoryGirl.build( :ib_contract, :sec_type => :option),
		FactoryGirl.build( :ib_contract, :sec_type => 'OPT'),
		FactoryGirl.build( :default_option ) ].each do |contract|
	   expect( contract).not_to be_bag
	   expect( contract).not_to be_bond
	   expect( contract).not_to be_stock
	   expect( contract).to be_option
	   expect( contract).to be_valid
   end
	end


	context IB::Option.from_osi( 'AAPL130119C00500000' ) do

		it 'builds a valid Option contract from OSI code' do
			expect( subject).to be_option
			expect( subject).to be_valid
			expect( subject.symbol).to eq 'AAPL'
			expect( subject.expiry).to eq '130118' # <- NB: Change in date!
			expect( subject.right).to eq :call
			expect( subject.strike).to eq 500
			#subject.osi.should == 'AAPL  130119C00500000'
		end

		it_behaves_like 'Contract'
	end

		 end # describe 
