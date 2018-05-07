module IB
	module Symbols

		def self.allocate_collection name  # name might be a string or a symbol
			symbol_table = Module.new do
				extend Symbols
				extend Enumerable
				def self.yml_file
					File.expand_path("../../../../symbols/#{name.to_s.downcase.split("::").last}.yml",__FILE__ )
				end

				def self.each &b
					contracts.values.each &b
				end
			end   # module new

			name =  name.to_s.camelize.to_sym
			the_collection = if	IB::Symbols.send  :const_defined?, name  
												 IB::Symbols.send :const_get, name
											 else
												 IB::Symbols.const_set  name, symbol_table   	
											 end
			the_collection.send :read_collection
			the_collection # return_value
		 
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
			if symbol.is_a? String
				symbol.to_sym
			elsif symbol.is_a? Symbol
				symbol
			else
				symbol.to_i
			end
			contracts[ symbol ] = contract
			store_collection
		end

		def remove_contract symbol
			@contracts.delete  symbol 
			store_collection
		end






	end # module Symbols
end #  module IB
