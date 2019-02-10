module IB
	class Account < IB::Model
		include BaseProperties
#		include Redis::Objects
		#  attr_accessible :alias, :account, :connected

		prop :account,  # String 
			:alias,     # 
			:type,
			:last_updated,
			:connected => :bool

#		redis_id_field :account
#		value :my_alias
#		value :the_account
#		value :active


		validates_format_of :account, :with =>  /\A[D]?[UF]{1}\d{5,8}\z/ , :message => 'should be (X)X00000'

		# in tableless mode the scope is ignored

		has_many :account_values
		has_many :portfolio_values
		has_many :contracts
		has_many :orders
		has_many :focuses

		def default_attributes
			super.merge account: 'X000000'
			super.merge alias: ''
			super.merge type: 'Account'
			super.merge connected: false
		end

		def logger  #nodoc#
			Connection.logger
		end

		# Setze Account connect/disconnect und undate!
		def connect!
			update_attribute :connected , true
		end 
		def disconnect!
			update_attribute :connected , false
		end 

		def print_type #nodoc#
			(test_environment? ? "demo_"  : "") + ( user? ? "user" : "advisor" )
		end

		def advisor?
			!!(type =~ /Advisor/ || account =~ /\A[D]?[F]{1}/)
		end

		def user?
			!!(type =~ /User/ || account =~ /\A[D]?[U]{1}/)
		end

		def test_environment?
			!!(account =~ /^[D]{1}/)
		end

		def == other
			super(other) ||
				other.is_a?(self.class) && account == other.account
		end 

		def to_human
			a = if self.alias.present?  && self.alias != account
						" alias: "+ self.alias
					else
						""
					end
				"<#{print_type} #{account}#{a}>"
		end

		def name  #nodoc#
			self.alias.present? ? self.alias : account
		end

#		alias :id :account
end # class

end # module
