module IB
	module Symbols

=begin
Creates a Class and associates it with a filename

raises an IB::Error in case of a conflict with existing class-names 
=end
	
# set the Pathname to "ib-ruby/symbols" by default
		@@dir= Pathname.new File.expand_path("../../../../symbols/", __FILE__ ) 

		def self.set_origin directory
			p = Pathname.new directory
			@@dir = p if p.directory? 
		rescue Errno::ENOENT
			error "Setting up origin for symbol-files --> Directory (#{directory}) does not exist" 
		end

		def self.allocate_collection name  # name might be a string or a symbol
			symbol_table = Module.new do
				extend Symbols
				extend Enumerable
				def self.yml_file
					@@dir + name.to_s.downcase.split("::").last.concat( ".yml" )
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
			if the_collection.is_a? IB::Symbols
				the_collection.send :read_collection if the_collection.all.empty?
				the_collection # return_value
			else
				error "#{the_collection} is already a Class" 
				nil
			end
		end

		def purge_collection
				yml_file.delete
				@contracts =  nil
		end

=begin
cuts the Collection in `bunch_count` pieces. Each bunch is delivered to the block.

Sleeps for `sleeping time` between processing bunches

Returns count of created bunches
=end
		def bunch( bunch_count = 50 , sleeping_time = 1)
			en = self.each
			the_size =  en.size
			i =  0 
			loop do
				the_start = i * bunch_count
				the_end =  the_start + bunch_count
				the_end = the_size -1 if the_end >= the_size
				it  = the_start .. the_end
				yield it.map{|x| en.next rescue nil}.compact
				break if  the_end == the_size -1 
				i+=1
				sleep sleeping_time
			end 
			 i -1  # return counts of bunches
		end

		def read_collection
			if  yml_file.exist?
				contracts.merge! YAML.load_file yml_file rescue contracts
			else
			 yml_file.open( "w"){}
			end
		end

		def store_collection
			 yml_file.open( 'w' ){|f| f.write @contracts.to_yaml}
		end

		def add_contract symbol, contract
			if symbol.is_a? String
				symbol.to_sym
			elsif symbol.is_a? Symbol
				symbol
			else
				symbol.to_i
			end
			# ensure that evey Sybmol::xxx.yyy entry has a description
			contract.description =  contract.to_human[1..-2] if contract.description.nil?
			# overwrite contract if existing
			contracts[ symbol ] = contract.essential
			store_collection
		end

		def remove_contract symbol
			@contracts.delete  symbol 
			store_collection
		end


		def to_human
			self.to_s.split("::").last
		end



		module Unspecified
			extend Symbols
		end

	end # module Symbols
end #  module IB
