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
