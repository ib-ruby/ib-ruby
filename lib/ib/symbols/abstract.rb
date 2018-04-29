module IB
	module Symbols

		def self.allocate_collection name  # name has to ba a capitalized symbol
			symbol_table = Module.new do
				extend Symbols
				def self.yml_file
					File.expand_path("../../../../symbols/#{name.to_s.split("::").last}.yml",__FILE__ )
				end
			end   # module new
			if	IB::Symbols.send  :const_defined?, name  
				IB::Symbols.send :const_get, name
			else
				IB::Symbols.const_set  name, symbol_table   	
			end

		 
		end

		def purge_collection
				`rm #{yml_file}`
				@contracts =  nil
		end

		def read_collection
			if File.exist? yml_file
				contracts.merge! YAML.load_file yml_file
			else
				`touch #{yml_file}`
			end
		end

		def store_collection
			File.open( yml_file, 'w' ){|f| f.write @contracts.to_yaml}
		end

		def add_contract symbol, contract
			contracts[ symbol.to_sym ] = contract
			store_collection
		end

		def remove_contract symbol
			@contracts.delete  symbol 
			store_collection
		end






	end # module Symbols
end #  module IB
