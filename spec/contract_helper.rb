=begin
request con_id for a given  IB::Contract

returns the con_id's

After calling the helper-function, the fetched ContractDetail-Messages are still present in received-buffer 
=end

def request_con_id  contract: IB::Symbols::Stocks.wfc 

		ib =  IB::Connection.current
		ib.clear_received
		raise 'Unable to verify contract, no connection' unless ib && ib.connected?

		ib.send_message :RequestContractDetails, contract: contract
		ib.wait_for :ContractDetailsEnd

		ib.received[:ContractData].contract.map &:con_id  # return an array of con_id's

end

shared_examples_for "correctly query's the tws" do
	
		it "query_contract does not raise an error" do
			expect { contract.query_contract }.not_to raise_error
		end


		it "query_contract resets con_id" do
			query_contract =  contract.query_contract 
			unless contract.sec_type.nil?
			expect( contract.con_id ).to be_zero 
			end
		end
		it "verify does intitialize con_id and contract_detail " do
			contract.verify do | c |
			expect( c.con_id ).not_to be_zero
			expect( c.contract_detail).to be_a IB::ContractDetail
			end
		end 

		it "verify returns a number" do
		  expect( contract.verify ).to be > 0
		end

		
end
shared_examples_for "invalid query of tws"  do
	
		it "does not verify " do
		  contract.verify
		expect(  should_log /Not a valid Contract/ ).to be_truthy
		end

		it "returns zero" do
		  expect( contract.verify ).to be_zero
		end
		
end
