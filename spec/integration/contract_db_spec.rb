require 'integration_helper'





describe "Build Contract-Database", :connected => true, :integration => true do

  before(:all) do
    verify_account
    raise "works only in db-backed mode " unless IB.db_backed?
  end

 # after(:all) { close_connection }
## An Order requires a valid contact-record to act on.
## The idea is to maintain a database of contract-records to refer on.
## Here we test the integrity of the database
  #first the database is build
  #some contents are changed
  #then it is updated
  let!( :list_of_symbols ) {	[ "AGU", "DE", "LNN", "TAP", "GPS", "T", "A", "GE" ] }

  it{ expect( list_of_symbols ).to have_exactly(8).items }
  context "BuildDB" do
  let!( :number_of_datasets ){ list_of_symbols.size }


#    after(:all) { clean_connection } # Clear logs and message collector

  #  it { expect( @ib.received[:ContractData]).to have_exactly(1).contract_data }
  #  it { expect( @ib.received[:ContractDataEnd]).to have_exactly(1).contract_data_end }
	let( :db ){ list_of_symbols.map{|s| FactoryGirl.create( :default_stock, symbol:s).read_contract_from_tws } }
	  let( :agu) { FactoryGirl.create( :default_stock, symbol:list_of_symbols.first )}
	  let( :agu_canada) { FactoryGirl.create :default_stock, symbol:list_of_symbols.first, currency:'CAD' }
	it{ expect( db ).to have_exactly(number_of_datasets).items }
	it{ expect( IB::Contract.count).to eq number_of_datasets }
  it "update contract_data " do
	  IB::Contract.all.each do |y| 
		  expect{ y.read_contract_from_tws }.not_to change{ y }
	  end
  end
  it "try to save duplicate Dataset" do
	  expect{ agu.read_contract_from_tws }.to raise_error ActiveRecord::RecordNotUnique
	  # important: ensure that invalid datasets are destroyed immediately 
	  agu.destroy
  end

  it "try to save the same stock in a different currency" do
	  ## the first using of the var (agu_canada) creates it, which should be reflected in the db
	  expect{ agu_canada }.to change{ IB::Contract.count }.by(1)
	  # the second using does not lead to a creation of a db-object
	  expect{ agu_canada.read_contract_from_tws }.not_to raise_error 
  end



  end #context
end # describe

