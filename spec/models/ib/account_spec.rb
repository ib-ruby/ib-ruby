require 'spec_helper'

shared_examples_for 'a valid Account' do | accounts |
  accounts.each do | account_id |
  it "#{account_id} can be saved" do
    subject.account = account_id
    puts "Invalid Account #{subject.account}"
    expect(subject.save).to be
  end # it

end  # each
end  # shared example
shared_examples_for 'a invalid Account' do | accounts |
  accounts.each do | account_id |
  it "#{account_id} cannot be saved" do
    subject.account = account_id
    expect(subject.save).not_to be
  end # it
end  # each
end  # shared example
shared_examples_for 'a valid User' do | accounts |
  it_behaves_like 'a valid Account', accounts
  accounts.each do | account_id |
    it "#{account_id} is a User" do
    subject.account = account_id
    expect(subject.advisor?).not_to be
    expect(subject.user?).to be
    expect(subject.print_type).to match /user/
  end # it
  end  # each
end  # shared example
shared_examples_for 'a valid Advisor' do | accounts |
  it_behaves_like 'a valid Account', accounts
  accounts.each do | account_id |
    it "#{account_id} is a Advisor" do
    subject.account = account_id
    expect(subject.advisor?).to be
    expect(subject.user?).not_to be
    expect(subject.print_type).to match /advisor/
  end # it
  end  # each
end  # shared example
shared_examples_for 'a valid Testaccount' do | accounts |
  it_behaves_like 'a valid Account', accounts
  accounts.each do | account_id |
    it "#{account_id} is a Testaccount" do
    subject.account = account_id
    expect(subject.test_environment?).to be
  end # it
  end  # each
end  # shared example

describe IB::Account do

  let( :valid_advisors )  { ['F1021786', 'F653317' ] }
  context 'Valid Advisor' do
    #  subject { IB::Account }
    #    it_behaves_like  'a valid Account' , valid_advisors 
    it_behaves_like  'a valid Advisor' , ['F1021786', 'F653317','DF653317'] #valid_advisors 
    it_behaves_like  'a valid User',  ['U1021786', 'U653317','DU1021786' ] 
    it_behaves_like  'a valid Testaccount', ['DU1021786', 'DU653317','DF1021786', 'DF653317']  
    it_behaves_like  'a invalid Account',  ['U17021786', '653317', 'DZU653317', 'DU67' ,'F17021786', '653317', 'DZUF53317', 'DF67', 'DU1021786u', 'DU6537', 'DF10217 86', 'DF6517']  
  end 


  context 'assign Contract and Order', focus:true do
    let( :account ){ IB::Account.new :account => 'U1021786' }
    let( :contract ){ IB::Stock.new :symbol => 'USO' }
    let( :order ){ IB::Order.new  :perm_id => 123456, :local_id => 1, total_quantity: 100,
				  :limit_price => 13, :action => 'BUY', :order_type => 'LMT'}
    let( :state ){ IB::OrderState.new :perm_id => 123456, :local_id => 1, :remaining => 100,
		   average_price: 0.0, parent_id:0, client_id:0, price: 0.0, :status => 'submitted' }
    
    let( :executed_state ){ IB::OrderState.new :perm_id => 123456, :local_id => 1, :remaining => 0,
		   average_price: 1.0, parent_id:0, client_id:0, price: 1.0, :status => 'executed' }
    it { expect( account.save ).to be }
    it { expect( contract.save ).to be }
    it { expect( order.save ).to be }
    it { expect( state.save ).to be }

    it 'assign Order to Contract and then both to the account' do
     account.orders.update_or_create order, :perm_id
     expect{ contract.orders.update_or_create order, :perm_id }.to change { contract.orders.size }.by 1
     expect{ order.order_states << state }.to change{ order.order_states.size}.by 1
     expect( contract.orders.last.order_states ).not_to be_empty
     expect( contract.orders.last.order_states.last ).to eq state
     expect( account.orders.last.order_states ).not_to be_empty

     expect{ order.order_states << executed_state }.to change{ account.orders.last.order_states.size }.by 1

    
    end

    end





end
