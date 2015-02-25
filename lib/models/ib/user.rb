module IB
class User < IB::Account
	 belongs_to :advisor, :class_name => "Account", :foreign_key => "advisor_id"
	 
	 scope :active,  ->(advisor) {  where( :connected => true ).where( :advisor_id => advisor.id )} rescue nil
	

end
end # module
