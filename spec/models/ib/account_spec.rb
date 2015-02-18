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
  context 'Valid Advisor' , focus:true do
    #  subject { IB::Account }
    #    it_behaves_like  'a valid Account' , valid_advisors 
    it_behaves_like  'a valid Advisor' , ['F1021786', 'F653317','DF653317'] #valid_advisors 
    it_behaves_like  'a valid User',  ['U1021786', 'U653317','DU1021786' ] 
    it_behaves_like  'a valid Testaccount', ['DU1021786', 'DU653317','DF1021786', 'DF653317']  
    it_behaves_like  'a invalid Account',  ['U17021786', '653317', 'DZU653317', 'DU67' ,'F17021786', '653317', 'DZUF53317', 'DF67', 'DU1021786u', 'DU6537', 'DF10217 86', 'DF6517']  
  end 



end
