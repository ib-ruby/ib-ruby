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


  def place_order  o: order, contract: nil
    o.contract =  contract if order.contract.nil?
    o.account =  account
    if o.contract.nil?
      IB::Gateway.logger.error {"place order --> No Contract specified .::. #{order.to_human}"}
    else
      result = o.contract.update_contract do | msg |
	#  con_id and exchange fully qualify a contract, no need to transmit other data
	contracts.update_or_create msg.contract, 'con_id'
	tws_contract =  IB::Contract.new con_id: msg.contract.con_id, exchange: msg.contract.exchange
	IB::Gateway.tws.place_order order, tws_contract
      end 
      unless result.is_a? IB::Contract
	IB::Gateway.logger.error {"place order --> Invalid Contract specified .::. #{order.to_human}"}
      end

    end # branch
  end # place order
end
end
