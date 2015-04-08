module IB
class Account < IB::Model
    include BaseProperties
  #  attr_accessible :name, :account, :connected

  prop :account,  # String 
       :name,     # 
       :type,
       :connected => :bool


  validates_format_of :account, :with =>  /\A[D]?[UF]{1}\d{5,8}\z/ , :message => 'should be (X)X00000'

  # in tableless mode the scope is ignored
  scope :of_ib_user_id, ->(account) { where :account => account.downcase } rescue nil

  has_many :account_values
  has_many :portfolio_values
  has_many :contracts
  has_many :orders

    def default_attributes
      super.merge account: 'X000000'
      super.merge name: ''
      super.merge type: 'Account'
      super.merge connected: false
    end

  # Setze Account connected/disconnected und undate!
  def connected!
    update_attribute :connected , true
  end # connected!
  def disconnected!
    update_attribute :connected , false
  end # disconnected!

  def print_type
      (test_environment? ? "demo_"  : "") + ( user? ? "user" : "advisor" )
  end

  def advisor?
    type =~ /Advisor/ || account =~ /\A[D]?[F]{1}/
  end

  def user?
    type =~ /User/ || account =~ /\A[D]?[U]{1}/
  end

  def test_environment?
    account =~ /^[D]{1}/
  end

  def == other
     super(other) ||
     other.is_a?(self.class) && account == other.account
  end 

  def simple_account_data_scan search_key, search_currency=nil
    if account_values.is_a? Array
      if search_currency.present? 
	account_values.find_all{|x| x.key.match( search_key )  && x.currency == search_currency.upcase }
      else
	account_values.find_all{|x| x.key.match( search_key ) }
      end

    else
      if search_currency.present?
	account_values.where( ['key like %', search_key] ).where( currency: search_currency )
      else  # any currency
	account_values.where( ['key like %', search_key] )
      end
    end
  end

  def open_orders
   orders.map{|y| y.status == 'submitted' || y.status== 'presubmitted'}.compact
  end

  def finished_orders
    orders.map{|y| s.status == 'executed' }.compact

  end
=begin
Account#LocateOrder
given any key of local_id, perm_id and invest_order_id
(If multible keys are specified, only the first ist used for the searching )
the associated Orderrecord is returned
=end
    # somtimes (order_ref) IB::Order-fields are stings!  
    # Therefor the comparism has to be done explicity ba converting to integer
    def locate_order local_id: nil, perm_id: nil, order_ref: nil
      search_option= [ local_id.present? ? [:local_id , local_id] : nil ,
		       perm_id.present? ? [:perm_id, perm_id] : nil,
		       invest_order_id.present? ? [:order_ref , order_ref ] : nil ].compact.first
      orders.detect{|x| x[search_option.first].to_i == search_option.last.to_i }
    end
      

=begin
Account#PlaceOrder
requires an IB::Order as parameter. 
If attached, the associated IB::Contract is used to specify the tws-command
The associated Contract overtakes a parallel specified one

The method validates the contract and returns the local_id of the submitted order


=end

  def place_order  order:, contract: nil
    order.contract =  contract if order.contract.nil?
    order.account =  account
    local_id =  nil
    if order.contract.nil?
      IB::Gateway.logger.error {"place order --> No Contract specified .::. #{order.to_human}"}
    else
      result = order.contract.update_contract do | msg |
	#  con_id and exchange fully qualify a contract, no need to transmit other data
	contracts.update_or_create msg.contract, 'con_id'
	tws_contract =  IB::Contract.new con_id: msg.contract.con_id, exchange: msg.contract.exchange
	local_id = IB::Gateway.current.place_order order, tws_contract
      end 
      unless result.is_a? IB::Contract
	IB::Gateway.logger.error {"place order --> Invalid Contract specified .::. #{order.to_human}"}
      end
      local_id  # return_value

    end # branch
  end # place 


=begin
Account#ModifyOrder

The order is specified indirectly via local_id or invest_order_id
The modification itself is done in the provided block.
=end

  def modify_order perm_id:nil, local_id: nil, invest_order_id: nil, &b
    order = locate_order perm_id: perm_id, local_id: local_id, invest_order_id: invest_order_id
    if order.is_a? IB::Order
     order = yield order  # specify modifications in the block
     IB::Gateway.current.modify_order order, order.contract 
      
    end
  end
  
end # class

end # module
