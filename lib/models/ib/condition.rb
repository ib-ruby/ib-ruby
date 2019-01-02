require 'ib/support'
module IB
  class OrderCondition < IB::Model
    include BaseProperties


		prop :operator,									# 1 ->  " >= " , 0 -> " <= "   see /lib/ib/constants # 338f
				:conjunction_connection,		# "o" -> or  "a"
				:contract
		def self.verify_contract_if_necessary c
  	 c.con_id.to_i.zero? ||( c.primary_exchange.blank? && c.exchange.blank?) ? c.verify! : c 
		end
		def condition_type
			error "condition_type method is abstract"
		end
		def  default_attributes
			 super.merge(  operator: ">=" , conjunction_connection: :and )
		end

		def serialize_contract_by_con_id
			[ contract.con_id , contract.primary_exchange.presence || contract.exchange ]
		end
		
		def serialize
			[ condition_type,  self[:conjunction_connection] ]
		end
	end



	class PriceCondition < OrderCondition
		using IBSupport   # refine Array-method for decoding of IB-Messages
		prop :price,
			:trigger_method  # see /models/ib/order.rb# 51 ff	 and /lib/ib/constants # 210 ff
		
		def default_attributes 
			super.merge( :trigger_method => :default  )
		end

		def condition_type 
		1
		end

		def self.make  buffer
				 m= self.new  conjunction_connection:  buffer.read_string,
					operator: buffer.read_int,
					price: buffer.read_decimal

					the_contract = IB::Contract.new con_id: buffer.read_int, exchange: buffer.read_string
					m.contract = the_contract
					m.trigger_method = buffer.read_int
					m

			end

		def serialize
		super << self[:operator] << price << serialize_contract_by_con_id <<  self[:trigger_method] 
		end

		# dsl:   PriceCondition.fabricate some_contract, ">=", 500
		def self.fabricate contract, operator, price
			error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator 
			self.new	operator: operator,
								price: price.to_i,
								contract: verify_contract_if_necessary( contract )
		end

	end

	class TimeCondition < OrderCondition
		using IBSupport   # refine Array-method for decoding of IB-Messages
		prop :time

		def condition_type 
			3
		end

		def self.make  buffer
			self.new  conjunction_connection:  buffer.read_string,
				operator: buffer.read_int,
				time: buffer.read_parse_date
		end

		def serialize
			t =  self[:time]
			if t.is_a?(String) && t =~ /^\d{8}\z/  # expiry-format yyymmmdd
				self.time = DateTime.new t[0..3],t[4..5],t[-2..-1]				  
			end
			serialized_time = case self[:time]   # explicity formatting of time-object
												when String
													self[:time]
												when DateTime	
													self[:time].gmtime.strftime("%Y%m%d %H:%M:%S %Z")
												when  Date, Time
													self[:time].strftime("%Y%m%d %H:%M:%S")
												end

			super << self[:operator] << serialized_time 
		end

		def self.fabricate operator, time
			self.new operator: operator, 
							time: time
		end
	end

	class ExecutionCondition < OrderCondition
		using IBSupport   # refine Array-method for decoding of IB-Messages
		
		def condition_type 
			5
		end

		def self.make  buffer
			m =self.new  conjunction_connection:  buffer.read_string,
									 operator: buffer.read_int

			the_contract = IB::Contract.new sec_type: buffer.read_string,
																			exchange: buffer.read_string,
																			symbol: buffer.read_string
			m.contract = the_contract
			m
		end

		def serialize
			super << contract[:sec_type] <<(contract.primary_exchange.presence || contract.exchange) << contract.symbol
		end
	
		def self.fabricate contract
			self.new contract: verify_contract_if_necessary( contract )
		end

	end

	class MarginCondition < OrderCondition
		using IBSupport   # refine Array-method for decoding of IB-Messages

		prop  :percent

		def condition_type 
			4
		end

		def self.make  buffer
			self.new  conjunction_connection:  buffer.read_string,
								operator: buffer.read_int,
								percent: buffer.read_int

		end

		def serialize
		super << self[:operator] << percent 
		end
		def self.fabricate operator,  percent
			error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator 
			self.new operator: operator, 
							percent: percent
		end
	end
	

	class VolumeCondition < OrderCondition
		using IBSupport   # refine Array-method for decoding of IB-Messages

		prop :volume

		def condition_type 
		6
		end

		def self.make  buffer
			m = self.new  conjunction_connection:  buffer.read_string,
										operator: buffer.read_int,
										volumne: buffer.read_int

			the_contract = IB::Contract.new con_id: buffer.read_int, exchange: buffer.read_string
			m.contract = the_contract
			m
		end

		def serialize

			super << self[:operator] << volume <<  serialize_contract_by.con_id 
		end

		# dsl:   VolumeCondition.fabricate some_contract, ">=", 50000
		def self.fabricate contract, operator, volume
			error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator 
			self.new	operator: operator,
								volume: volume,
								contract: verify_contract_if_necessary( contract )
		end
	end

	class PercentChangeCondition < OrderCondition
		using IBSupport   # refine Array-method for decoding of IB-Messages
		prop :percent_change

		def condition_type 
		7
		end

		def self.make  buffer
				m = self.new  conjunction_connection:  buffer.read_string,
											operator: buffer.read_int,
											percent_change: buffer.read_decimal

				the_contract = IB::Contract.new con_id: buffer.read_int, exchange: buffer.read_string
				m.contract = the_contract
				m
		end

		def serialize
			super << self[:operator] << percent_change  << serialize_contract_by_con_id 

		end
		# dsl:   PercentChangeCondition.fabricate some_contract, ">=", "5%"
		def self.fabricate contract, operator, change
			error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator 
				self.new	operator: operator,
									percent_change: change.to_i,
									contract: verify_contract_if_necessary( contract )
		end
	end
	class OrderCondition
		using IBSupport   # refine Array-method for decoding of IB-Messages
		# subclasses representing specialized condition types.

		Subclasses = Hash.new(OrderCondition)
		Subclasses[1] = IB::PriceCondition
		Subclasses[3] = IB::TimeCondition
		Subclasses[5] = IB::ExecutionCondition
		Subclasses[4] = IB::MarginCondition
		Subclasses[6] = IB::VolumeCondition
		Subclasses[7] = IB::PercentChangeCondition


		# This builds an appropriate subclass based on its type
		#
		def self.make_from  buffer
			condition_type = buffer.read_int
			OrderCondition::Subclasses[condition_type].make( buffer )
		end
	end  # class
end # module
