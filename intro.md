##  ib-ruby – An Introduction

Ib-ruby is a pure ruby implementation to access the IB-TWS-API.
It mirrors most of the information provided by the tws as Active-Model-Objects.

### Connect to the TWS

Assuming, the TWS ( FA-Account,»Friends and Family«,  is needed ) is running 
and API-Connections are enabled,  just instantiate IB::Gateway to connect i.e.

```
gw = IB::Gateway.new connect: true, host: 'localhost:7496' , client_id: 1001
```

The Connection-Object, which provides the status and recieves subscriptions of TWS-Messages, is
always present as 

```
  tws = IB::Connection.tws 
or
  tws =  gw.tws

```
The Gateway acts as a Proxy to the Connection-Object and provides a simple Security-Layer.
The method »connect« waits approx. 1 hour  for the TWS to start. IB::Gateway reconnects automatically if the 
transmission was interrupted. It is even possible to switch from one TWS to another

```
  gw.change_host host:  'new_host:new_port'  
  gw.prepare_connection
  gw.connect
```


### Read Account-Date

If you open the TWS-GUI you get a nice overview of all account-positions, the distribution of 
currencies, margin-using, leverage and other account-measures.

These informations are transmitted by the API, too. 
One can send a message to the tws and simply wait for the response.

The Gateway handles anything in the background and provides essential account-data
in a structured manner:


```
  gw.get_account_data
  gw.request_open_orders

Gateway
  --- Account 
        --- PortfolioValues
	--- AccountValues
	--- Orders

```
IB::Gateway provides an array of active Accounts. One is a Advisor-Account. Several tasks
are delegated to the accounts. An Advisor cannot submit an order for himself. An ordonary User
can only place orders for himself. 

The TWS sends data arbitrarily. Ib-ruby has to process them concurrently. Someone has to take care
of possible data-collistions. Therefor its not advisable to access the TWS-Data directly.
IB::Gateway provides wrapper-nethods 
```
 gw.for_active_accounts do |account |   ... end
 gw.for_selected_account( ib_account_id ) do |account|  ... end
```
However, Advisor and Users are directly available through
```
 gw.advisor	       --> Account-Object
 gw.active_accounts[n] --> Account-Object 
 gw.active_accounts    --> Array of user-accounts 	
```



PortfolioValues represent the portfolio-positions of the specified Account. 
Each PortfolioValue is an ActiveModel
and has the following structure, 

```
IB::PortfolioValue:  
    position: (integer), market_price: (float), market_value: (float), average_cost: (float)
    unrealized_pnl: (float), realized_pnl: (float), created_at: (date_time), updated_at: (date_time),
    contract: (IB::Contract),
    created_at: (date_time), updated_at: (date_time)
```
As usual, attributes are accessible through  PortfolioValue[:attribute], PortfolioValue['attribute']
or PortfolioValue.attribute and even PortfolioValue.call(attribute)
 
AccountValues prepresent any property of the Account, as displayed in the Account-Window of the TWS.
Each record has this structure:
```
IB::AccountValue:
    key: (string),
    value: (string)
    currency: (string)
    created_at: (date_time), updated_at: (date_time)
```

There is a simple method: IB::Account#SimpleAccountDateScan to select one or a group of 
AccountValues: IB::Account#simple_account_data_scan search_key, search_currency 
The parameter »search_key« is treated as a regular-expression, the parameter »currency« is optional.
Most AccountValue-Keys are split into the currencies present in the account.
To retrieve an ordered list  this snipplet helps

```
     account = gw.active_accounts[1]
     account_value = ->(item) do
       array = account.simple_account_data_scan(item).map{ |y| 
	      [y.value,y.currency] unless y.value.to_i.zero?  }.compact
       array.sort{ |a,b| b.last == 'BASE' ? 1 :  a.last  <=> b.last } # put base element in front
     end

     account_value['TotalCashBalance']
     => [["682343", "BASE"], ["1829", "AUD"], ["629503", "EUR"], ["-23081", "JPY"], ["56692", "USD"]]
```

Open (pending) Orders are retrieved by »gw.request_open_orders«. IB::Gateway, in this case the module
OrderHandling (in ib/order_handling.rb) updates the »orders«-Array of each Account. 
The Account#orders-Array consists of IB::Order-Entries:


```
IB::Order: local_id: (integer), side: "B/S", quantity: (integer), 
	   order_type: (validOrderType), 
	   limit_price:(float), aux_price:(float),
	   tif:("DAY/GTC/GTD"), order_ref: (string), 
	   perm_id: (integer), 
	   transmit: (boolean),
	   order_states: (array of IB::OrderState),
	   contract: (IB::Contract),
	   created_at: (date_time), updated_at: (date_time)
	   (only essential attributes are included)   

```
If an order gets filled while IB::Gateway is active, the IB::Account#Orders-Entries are updated.








