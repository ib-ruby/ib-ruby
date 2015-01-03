### Helpers for defining and retrieving contracts

shared_examples_for "correctly query's the tws" do
	
		it "query_contract does not raise an error" do
			expect { contract.query_contract }.not_to raise_error
		end


		it "query_contract resets con_id" do
			query_contract =  contract.query_contract 
			expect( contract.con_id ).to be_zero
		end
		it "read_contract does intitialize the con_id " do
			contract.read_contract_from_tws 
			expect( contract.con_id ).not_to be_zero
		end 

		it "read_contract does not change the object.id " do
		expect{  contract.read_contract_from_tws }.not_to change{ contract.id }
		end
		
end
shared_examples_for "invalid query of tws"  do
	
		it "does not changes the con_id  to zero" do
		expect(  contract.con_id ).to be_zero
		end
		it "does not change the object.id " do
		expect{  contract.read_contract_from_tws }.not_to change{ contract.id }
		end
		
end
