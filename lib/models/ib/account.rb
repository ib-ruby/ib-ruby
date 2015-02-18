module IB
class Account < IB::Model
    include BaseProperties
  #  attr_accessible :name, :account, :connected

  prop :account,  # String 
       :alias     # 


  validates_format_of :account, :with =>  /\A[D]?[UF]{1}\d{5,7}\z/ , :message => 'should be (X)X00000'

    def default_attributes
      super.merge account: 'X000000'
      super.merge alias: ''
    end

  # Setze Account connected/disconnected und undate!
  def connected!
    update_attribute :connected , true
  end # connected!
  def disconnected!
    update_attribute :connected , false
  end # disconnected!

  def advisor?
    account =~ /[F]{1}/
  end

  def user?
    account =~ /[U]{1}/
  end

  def test_environment?
    account =~ /^[D]{1}/
  end
end
end
