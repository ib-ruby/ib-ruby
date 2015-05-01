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

    else  # not tested!!
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
given any key of local_id, perm_id and order_ref
(If multible keys are specified, only the first is used for the searching )
and an optional status, which can be a string or a regexp ( status: /mitted/ matches Submitted and Presubmitted) 

The last associated Orderrecord is returned.
Thus if several Orders are placed with the same order_ref, the active one is returned

=end
    def locate_order local_id: nil, perm_id: nil, order_ref: nil, status: nil
      search_option= [ local_id.present? ? [:local_id , local_id] : nil ,
		       perm_id.present? ? [:perm_id, perm_id] : nil,
		       order_ref.present? ? [:order_ref , order_ref ] : nil ].compact.first
      matched_items =  search_option.nil? ? orders : orders.find_all{|x| x[search_option.first].to_i == search_option.last.to_i }
      if status.present?
	status = Regexp.new(status) unless status.is_a? Regexp
	matched_items.detect{|x| x.order_state.status =~ status }
      else
      matched_items.last  # return the last item
      end
    end
      

=begin
Account#PlaceOrder
requires an IB::Order as parameter. 
If attached, the associated IB::Contract is used to specify the tws-command
The associated Contract overtakes a parallel specified one

The method validates the contract and returns the local_id of the submitted order

Limit- and Aux-Prices are adjusted to Min-Tick, if auto_adjust is specified

=end

  def place_order  order:, contract: nil, auto_adjust: true
    # adjust the orderprice to  min-tick
    IB::Gateway.logger.progname =  'Account#PlaceOrder' 

    order.contract =  contract if order.contract.nil?
    order.contract.verify if  order.contract.con_id.blank?
    order.account =  account  # assign the account_id to the account-field of IB::Order
    local_id =  nil
    if order.contract.nil? || order.contract.con_id.blank?
      IB::Gateway.logger.error {"No Contract specified .::. #{order.to_human}"}
    else
      order.auto_adjust if auto_adjust
      c=  order.contract
      #  con_id and exchange fully qualify a contract, no need to transmit other data
      tws_contract =  IB::Contract.new con_id: c.con_id, exchange: c.exchange
      local_id = IB::Gateway.current.place_order order, tws_contract
    end 
    local_id  # return_value

  end # place 


=begin
Account#ModifyOrder
operates in two modi:

First: The order is specified  via local_id, perm_id or order_ref.
  It is checked, whether the order is still modificable.
  Then the Order ist provided through  the block. Any modification is done there. 
  Important: The Block has to return the modified IB::Order

Second: The order can be provided as parameter as well. This will be used
without further checking. The block is now optional. 
  Important: The OrderRecord must provide a valid Contract.

ModifyOrder in the simple version does not adjust the given prices to tick-limits.
This has to be done manualy in the proviede block
=end

  def modify_order perm_id: nil, local_id: nil, order_ref: nil, order:nil, &b

    IB::Gateway.logger.tap{ |l| l.progname = "Account #{account}#modify_order"}
    order = locate_order(  perm_id: perm_id, 
			  local_id: local_id, 
			  status: /ubmitted/ ,
			  order_ref: order_ref ) if order.nil?
    if order.is_a? IB::Order
     order = yield order if block_given?  # specify modifications in the block
    end
    if order.is_a? IB::Order
       IB::Gateway.current.modify_order order, order.contract 
     else
       IB::Gateway.logger.error{ " No suitable IB::Order provided/detected. Instead: #{order.inspect}" }
     end  
  end
  
end # class

end # module
