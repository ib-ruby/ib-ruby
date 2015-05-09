module IB
class Advisor < IB::Account
# Der Advisor kann auf Assets und auf verbundene User zugreifen
	# has_many :ib_assets, :through => :account_positions wird von Account geerbt
# Bezüge  innerhalb der Datenbanktabelle
  has_many :users, :class_name => "Account", :foreign_key => "advisor_id"
=begin
Advisor.active! gibt den derzeit aktiven Advisor-Account (als ActiveRecord::Relation) zurück.
=end
  scope :active!, ->{ where( connected: true ).first } rescue nil
=begin
Ermittelt alle mit dem aktiven Advisor verknüpften aktiven Useraccounts.
Das Ergebnis ist eine ActiveRecord::Relation
=end
  def self.active_users
	  unless active!.empty?
		  active!.users.where( connected: true ) 
	  end
  end
end # class
end # module
