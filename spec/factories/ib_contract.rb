#This will guess the Account class
FactoryGirl.define do
	factory :ib_contract, class:IB::Contract do
		con_id 	265598 # apple7765  # gps 2586596 ewp
		currency 'USD' 
		exchange 'SMART' 
		sec_type  :stock
	end
	# Stellt deutlich mehr Attribute zur Verfügung, als für die 
	# Abfrage benötigt werden. query_contract extrahiert die notwendigen Attribute
	factory :ib_option_contract, class:IB::Contract do
		symbol  'AAPL'
		sec_type  :option
		expiry  '201503'
		strike  110
		right  :put
		sec_id  'US0378331005'
		sec_id_type  'ISIN'
		multiplier  10
		exchange  'SMART'
		currency  'USD'
		local_symbol  'AAPL  150320C00110000'

	end
	# minimale Attribute für die Abfrage eines Contract-Datensatzes aus der TWS
	factory :con_id_contract, class:IB::Contract do
		sec_type  :stock
		con_id 	 '7516'
	end
	factory :default_stock, class:IB::Stock do
		symbol 	 'GPS'
	end
	factory :default_future, class:IB::Future do
		symbol 	 'ZN'
		expiry  '201503'
		exchange 'ECBOT'
	end
	factory :default_forex, class:IB::Forex do
		symbol 	 'EUR'
	end
	# stellt  Minimale Attribute für die Abfrage eines Optionsdatensatze aus der TWS bereit
	# Test funktionieren nur, wenn explizit IB::Option angegeben wird
	# Ansonsten wird type nicht gesetzt und die Options-spezifischen Methoden sind nicht verfügbar
	factory :default_option, class:IB::Option do
		symbol  'F'
		expiry  '201503'
		strike 15 
		right  :put
	end



end
