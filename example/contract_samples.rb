#!/usr/bin/env ruby
# ---------------------------------------------------------------------------------- #
#                     C O N T R A C T  S A M P L E S                                 #
#
# Sample Contracts for ib-ruby with 1:1 comparism to python code         
#
# based on »ContractSamples.py« (python-implementation of the tws-api)
# which is protected by the following copyright
#
#Copyright (C) 2016 Interactive Brokers LLC. All rights reserved.  This code is
#subject to the terms and conditions of the IB API Non-Commercial License or the
# IB API Commercial License, as applicable. 
#
#

# This script just generates contracts 
# If called from the command line, it prints a list

require 'bundler/setup'
require 'yaml'
require 'ib-ruby'
include IB

module ContractSamples

    """ Usually, the easiest way to define a Stock/CASH contract is through 
    these four attributes.  """

    def rEurGbpFx
      Symbols::Forex[:eurgbp]
    end
=begin
 [cashcontract]
        contract = Contract()
        contract.symbol = "EUR"
        contract.secType = "CASH"
        contract.currency = "GBP"
        contract.exchange = "IDEALPRO"
=end

    def rIndex
      Contract.new symbol: 'DAX', sec_type: :index, currency: 'EUR', exchange: 'DTB'
    end
=begin
   [indcontract]
        contract = Contract()
        contract.symbol = "DAX"
        contract.secType = "IND"
        contract.currency = "EUR"
        contract.exchange = "DTB"
=end 


    def rCFD
    Contract.new symbol: 'IBDE30', sec_type:  :cfd, currency: 'EUR'
    end
=begin
#! [cfdcontract]
        contract = Contract()
        contract.symbol = "IBDE30"
        contract.secType = "CFD"
        contract.currency = "EUR"
        contract.exchange = "SMART"
=end


    def rEuropeanStock
      Stock.new symbol:  'SIE', currency: 'EUR'
    end
=begin
	contract = Contract()
        contract.symbol = "SIE"
        contract.secType = "STK"
        contract.currency = "EUR"
        contract.exchange = "SMART"
=end

    def rOptionAtIse
	Option.new symbol: 'ARGO',
		    currency: "USD",
		    exchange: "ISE",
		    expiry:  Symbols::Futures.next_expiry,
		    right: :call,
		    strike: 10,
		    multiplier: 100
    end
=begin
        contract = Contract()
        contract.symbol = "BPX"
        contract.secType = "OPT"
        contract.currency = "USD"
        contract.exchange = "ISE"
        contract.lastTradeDateOrContractMonth = "20160916"
        contract.right = "C"
        contract.strike = 65
        contract.multiplier = "100"
=end

    def rBondWithCusip
	Contract.new symbol: '912828C57', sec_type: :bond, currency: 'USD' 
    end
=begin
#! [bondwithcusip]
            contract = Contract()
            # enter CUSIP as symbol
            contract.symbol= "912828C57"
            contract.secType = "BOND"
            contract.exchange = "SMART"
            contract.currency = "USD"
=end

    def rBond
            Contract.new con_id: 267433416
    end
=begin
#! [bond]
            contract = Contract()
            contract.conId = 267433416
            contract.exchange = "SMART"
=end


    def rMutualFund
      Contract.new symbol: 'VINIX', sec_type: :fund, exchange: 'FUNDSERV', currency: 'USD'
    end
=begin
#! [fundcontract]
            contract = Contract()
            contract.symbol = "VINIX"
            contract.secType = "FUND"
            contract.exchange = "FUNDSERV"
            contract.currency = "USD"
=end

    def rCommodity
      Contract.new symbol: 'XAUUSD', sec_type: :commodity, currency: 'USD'
    end
=begin
#! [commoditycontract]
            contract = Contract()
            contract.symbol = "XAUUSD"
            contract.secType = "CMDTY"
            contract.exchange = "SMART"
            contract.currency = "USD"
=end
    

    def rUSStock
        #In the API side, NASDAQ is always defined as ISLAND in the exchange field
      Stock.new symbol: 'IBKR', exchange: 'ISLAND'
    end
=begin
        #! [stkcontract]
        contract = Contract()
        contract.symbol = "IBKR"
        contract.secType = "STK"
        contract.currency = "USD"
        contract.exchange = "ISLAND"
=end

    def rUSStockWithPrimaryExch
        #Specify the Primary Exchange attribute to avoid contract ambiguity 
		#(there is an ambiguity because there is also a MSFT contract with primary exchange = "AEB")
      Stock.new symbol: 'MSFT', primary_exchange: 'ISLAND'
    end
=begin
        #! [stkcontractwithprimary]
        contract = Contract()
        contract.symbol = "MSFT"
        contract.secType = "STK"
        contract.currency = "USD"
        contract.exchange = "SMART"
        contract.primaryExchange = "ISLAND"
=end
            
    def rUSStockAtSmart
      Stock.new symbol: 'IBKR'
    end
=begin
        contract = Contract()
        contract.symbol = "IBKR"
        contract.secType = "STK"
        contract.currency = "USD"
        contract.exchange = "SMART"
        return contract
=end

    def rUSOptionContract
      Option.new symbol: 'GOOG',
		 strike: 1100,
		 multiplier: 100,
		 right: :call,
		 expiry:  Symbols::Futures.next_expiry
    end
=begin
        #! [optcontract_us]
        contract = Contract()
        contract.symbol = "GOOG"
        contract.secType = "OPT"
        contract.exchange = "SMART"
        contract.currency = "USD"
        contract.lastTradeDateOrContractMonth = "20170120"
        contract.strike = 615
        contract.right = "C"
        contract.multiplier = "100"
=end

    def rOptionAtBOX
      Option.new symbol: 'GOOG',
		 strike: 1200,
		 multiplier: 100,
		 right: :call,
		 expiry:  Symbols::Futures.next_expiry ,
		 exchange: 'BOX'
    end
=begin
        #! [optcontract]
        contract = Contract()
        contract.symbol = "GOOG"
        contract.secType = "OPT"
        contract.exchange = "BOX"
        contract.currency = "USD"
        contract.lastTradeDateOrContractMonth = "20170120"
        contract.strike = 615
        contract.right = "C"
        contract.multiplier = "100"
=end

=begin
    """ Option contracts require far more information since there are many 
    contracts having the exact same attributes such as symbol, currency, 
    strike, etc. This can be overcome by adding more details such as the 
    trading class"""
=end
    def rOptionWithTradingClass
        Option.new  symbol: 'SANT',
        exchange: "MEFFRV",
        currency: "EUR",
	expiry:  Symbols::Futures.next_expiry,
        strike: 7.5,
        right: :call,
        multiplier: 100,
        trading_class: "SANEU"
    end
=begin
        #! [optcontract_tradingclass]
        contract = Contract()
        contract.symbol = "SANT"
        contract.secType = "OPT"
        contract.exchange = "MEFFRV"
        contract.currency = "EUR"
        contract.lastTradeDateOrContractMonth = "20190621"
        contract.strike = 7.5
        contract.right = "C"
        contract.multiplier = "100"
        contract.tradingClass = "SANEU"
=end

=begin
    """ Using the contract's own symbol (localSymbol) can greatly simplify a
    contract description """
=end

    def rOptionWithLocalSymbol
      #Watch out for the spaces within the local symbol!
      Option.new local_symbol: "C DBK  DEC 20  1600",
		 exchange: 'DTB',
		 currency: 'EUR'
    end
=begin
        #! [optcontract_localsymbol]
        contract = Contract()
        contract.localSymbol = "C DBK  DEC 20  1600"
        contract.secType = "OPT"
        contract.exchange = "DTB"
        contract.currency = "EUR"
=end

=begin
     Dutch Warrants (IOPTs) can be defined using the local symbol or conid 
=end
	
    def rDutchWarrant
	Contract.new sec_type: :dutch_option,
		     exchange: 'SBF',
		     currency: 'EUR',
		     local_symbol: 'B881G'
    end
=begin
        #! [ioptcontract]
        contract = Contract()
        contract.localSymbol = "B881G"
        contract.secType = "IOPT"
        contract.exchange = "SBF"
        contract.currency = "EUR"
        #! [ioptcontract]
        return contract
=end

=begin
    Future contracts also require an expiration date but are less
    complicated than options.
=end

    def rSimpleFuture
      Future.new symbol: 'ES', exchange: 'GLOBEX', 
		 expiry:  Symbols::Futures.next_expiry,
		 currency: 'USD'
    end
=begin
        #! [futcontract]
        contract = Contract()
        contract.symbol = "ES"
        contract.secType = "FUT"
        contract.exchange = "GLOBEX"
        contract.currency = "USD"
        contract.lastTradeDateOrContractMonth = "201612"
=end

=begin
    Rather than giving expiration dates we can also provide the local symbol
    attributes such as symbol, currency, strike, etc. 
=end

    def rFutureWithLocalSymbol
      Future.new symbol: 'ES', exchange: 'GLOBEX', 
		 currency: 'USD',
		 local_symbol: 'ESU8'
    end
=begin
        #! [futcontract_local_symbol]
        contract = Contract()
        contract.secType = "FUT"
        contract.exchange = "GLOBEX"
        contract.currency = "USD"
        contract.localSymbol = "ESU6"
=end


    def rFutureWithMultiplier
	Future.new symbol: 'DAX', exchange: 'DTB', 
		 expiry:  Symbols::Futures.next_expiry,
		 currency: 'EUR',
		 multiplier: 5
    end
=begin
        #! [futcontract_multiplier]
        contract = Contract()
        contract.symbol = "DAX"
        contract.secType = "FUT"
        contract.exchange = "DTB"
        contract.currency = "EUR"
        contract.lastTradeDateOrContractMonth = "201609"
        contract.multiplier = "5"
=end



    def rFuturesOnOptions
      Contract.new sec_type: :future_option,
		    expiry:  Symbols::Futures.next_expiry,
		   exchange: 'GLOBEX',
		   currency: 'USD',
		   strike: 1400,
		   right: :call,
		   multiplier: 250
    end
=begin
        #! [fopcontract]
        contract = Contract()
        contract.symbol = "SPX"
        contract.secType = "FOP"
        contract.exchange = "GLOBEX"
        contract.currency = "USD"
        contract.lastTradeDateOrContractMonth = "20180315"
        contract.strike = 1025
        contract.right = "C"
        contract.multiplier = "250"
=end

=begin
     It is also possible to define contracts based on their ISIN (IBKR STK sample). 
=end
    def rByISIN
      Stock.new sec_id_type: 'ISIN', sec_id: "US45841N1072"
    end
=begin
        contract = Contract()
        contract.secIdType = "ISIN"
        contract.secId = "US45841N1072"
        contract.exchange = "SMART"
        contract.currency = "USD"
        contract.secType = "STK"
=end

=begin
    Or their conId (EUR.uSD sample).
    Note: passing a contract containing the conId can cause problems if one of 
    the other provided attributes does not match 100% with what is in IB's 
    database. This is particularly important for contracts such as Bonds which 
    may change their description from one day to another.
    If the conId is provided, it is best not to give too much information as
    in the example below.
=end

    def rByConId
      Contract.new sec_type: :forex, con_id: 12087792, exchange: 'IDEALPRO'
    end
=begin
        contract = Contract()
        contract.secType = "CASH"
        contract.conId = 12087792
        contract.exchange = "IDEALPRO"
=end

=begin
    Ambiguous contracts are great to use with reqContractDetails. This way
    you can query the whole option chain for an underlying. Bear in mind that
    there are pacing mechanisms in place which will delay any further responses
    from the TWS to prevent abuse. 
=end

    def rOptionForQuery
      Option.new symbol: 'FISV'
    end
=begin
        #! [optionforquery]
        contract = Contract()
        contract.symbol = "FISV"
        contract.secType = "OPT"
        contract.exchange = "SMART"
        contract.currency = "USD"
=end
    def rOptionComboContract

       Bag.new symbol: 'DBK', currency: 'EUR', exchange: 'DTB', legs:
	[  ComboLeg.new( con_id: 197397509 , action: :buy, exchange: 'DTB', ratio: 1),   #DBK JUN 15 2018 C 
           ComboLeg.new( con_id: 197397584,  action: :sell, exchange: 'DTB', ratio: 1 ) ] #DBK JUN 15 2018 P
    end

=begin
        contract = Contract()
        contract.symbol = "DBK"
        contract.secType = "BAG"
        contract.currency = "EUR"
        contract.exchange = "DTB"

        leg1 = ComboLeg()
        leg1.conId = 197397509 #DBK JUN 15 2018 C
        leg1.ratio = 1
        leg1.action = "BUY"
        leg1.exchange = "DTB"


        leg2 = ComboLeg()
        leg2.conId = 197397584  #DBK JUN 15 2018 P
        leg2.ratio = 1
        leg2.action = "SELL"
        leg2.exchange = "DTB"

        contract.comboLegs = []
        contract.comboLegs.append(leg1)
        contract.comboLegs.append(leg2)
        #! [bagoptcontract]
        return contract


    """ STK Combo contract
    Leg 1: 43645865 - IBKR's STK
    Leg 2: 9408 - McDonald's STK """
=end
    def rStockComboContract
       Bag.new symbol: 'IBKR,MCD', currency: 'USD', legs:
	[  ComboLeg.new( con_id: 43645865, action: :buy, ratio: 1), # IKBR STK
           ComboLeg.new( con_id: 9408,	  action: :sell,ratio: 1 ) ] # MCD STK
    end
=begin
        #! [bagstkcontract]
        contract = Contract()
        contract.symbol = "IBKR,MCD"
        contract.secType = "BAG"
        contract.currency = "USD"
        contract.exchange = "SMART"

        leg1 = ComboLeg()
        leg1.conId = 43645865#IBKR STK
        leg1.ratio = 1
        leg1.action = "BUY"
        leg1.exchange = "SMART"

        leg2 = ComboLeg()
        leg2.conId = 9408#MCD STK
        leg2.ratio = 1
        leg2.action = "SELL"
        leg2.exchange = "SMART"

        contract.comboLegs = []
        contract.comboLegs.append(leg1)
        contract.comboLegs.append(leg2)
        #! [bagstkcontract]
        return contract
=end


=begin

    """ CBOE Volatility Index Future combo contract """
=end
    def rFutureComboContract
       Bag.new symbol: 'VIX', currency: 'USD', exchange: 'CFE', legs:
	[  ComboLeg.new( con_id: 256038899, action: :buy, exchange: 'CFE', ratio: 1), #  VIX FUT 201708
           ComboLeg.new( con_id: 260564703,  action: :sell, exchange: 'CFE', ratio: 1 ) ] # VIX FUT 201709
    end
=begin
        #! [bagfutcontract]
        contract = Contract()
        contract.symbol = "VIX"
        contract.secType = "BAG"
        contract.currency = "USD"
        contract.exchange = "CFE"

        leg1 = ComboLeg()
        leg1.conId = 256038899 # VIX FUT 201708
        leg1.ratio = 1
        leg1.action = "BUY"
        leg1.exchange = "CFE"

        leg2 = ComboLeg()
        leg2.conId = 260564703 # VIX FUT 201709
        leg2.ratio = 1
        leg2.action = "SELL"
        leg2.exchange = "CFE"

        contract.comboLegs = []
        contract.comboLegs.append(leg1)
        contract.comboLegs.append(leg2)
        #! [bagfutcontract]
        return contract

=end
    def rSmartFutureComboContract()
       Bag.new symbol: 'WTI', currency: 'USD', exchange: 'SMART', legs:
	[  ComboLeg.new( con_id: 55928698, action: :buy, exchange: 'IPE', ratio: 1), #  WTI future June 2017 
           ComboLeg.new( con_id: 55850663,  action: :sell, exchange: 'IPE', ratio: 1 ) ] # COIL future June 2017
    end
=begin
        #! [smartfuturespread]
        contract = Contract()
        contract.symbol = "WTI" # WTI,COIL spread. Symbol can be defined as first leg symbol ("WTI") or currency ("USD")
        contract.secType = "BAG"
        contract.currency = "USD"
        contract.exchange = "SMART"

        leg1 = ComboLeg()
        leg1.conId = 55928698 # WTI future June 2017
        leg1.ratio = 1
        leg1.action = "BUY"
        leg1.exchange = "IPE"

        leg2 = ComboLeg()
        leg2.conId = 55850663 # COIL future June 2017
        leg2.ratio = 1
        leg2.action = "SELL"
        leg2.exchange = "IPE"

        contract.comboLegs = []
        contract.comboLegs.append(leg1)
        contract.comboLegs.append(leg2)
        #! [smartfuturespread]
        return contract
=end
    def rInterCmdtyFuturesContract()
       Bag.new symbol: 'CL.BZ', currency: 'USD', exchange: 'NYMEX', legs:
	[  ComboLeg.new( con_id: 47207310, action: :buy, exchange: 'NYMEX', ratio: 1), #  CL Dec'16 @NYMEX
           ComboLeg.new( con_id: 47195961,  action: :sell, exchange: 'NYMEX', ratio: 1 ) ] # #BZ Dec'16 @NYMEX
    end
=begin
        #! [intcmdfutcontract]
	#
        contract = Contract()
        contract.symbol = "CL.BZ" #symbol is 'local symbol' of intercommodity spread. 
        contract.secType = "BAG"
        contract.currency = "USD"
        contract.exchange = "NYMEX"

        leg1 = ComboLeg()
        leg1.conId = 47207310 #CL Dec'16 @NYMEX
        leg1.ratio = 1
        leg1.action = "BUY"
        leg1.exchange = "NYMEX"

        leg2 = ComboLeg()
        leg2.conId = 47195961 #BZ Dec'16 @NYMEX
        leg2.ratio = 1
        leg2.action = "SELL"
        leg2.exchange = "NYMEX"

        contract.comboLegs = []
        contract.comboLegs.append(leg1)
        contract.comboLegs.append(leg2)
        #! [intcmdfutcontract]
        return contract


    @staticmethod
    def NewsFeedForQuery():
        #! [newsfeedforquery]
        contract = Contract()
        contract.secType = "NEWS"
        contract.exchange = "BT" #Briefing Trader
        #! [newsfeedforquery]
        return contract


    @staticmethod
    def BTbroadtapeNewsFeed():
        #! [newscontractbt]
        contract = Contract()
        contract.symbol  = "BT:BT_ALL" #BroadTape All News
        contract.secType = "NEWS"
        contract.exchange = "BT" #Briefing Trader
        #! [newscontractbt]
        return contract


    @staticmethod
    def BZbroadtapeNewsFeed():
        #! [newscontractbz]
        contract = Contract()
        contract.symbol = "BZ:BZ_ALL" #BroadTape All News
        contract.secType = "NEWS"
        contract.exchange = "BZ" #Benzinga Pro
        #! [newscontractbz]
        return contract


    @staticmethod
    def FLYbroadtapeNewsFeed():
        #! [newscontractfly]
        contract = Contract()
        contract.symbol  = "FLY:FLY_ALL" #BroadTape All News
        contract.secType = "NEWS"
        contract.exchange = "FLY" #Fly on the Wall
       #! [newscontractfly]
        return contract


    @staticmethod
    def MTbroadtapeNewsFeed():
        #! [newscontractmt]
        contract = Contract()
        contract.symbol = "MT:MT_ALL" #BroadTape All News
        contract.secType = "NEWS"
        contract.exchange = "MT" #Midnight Trader
        #! [newscontractmt]
        return contract

    @staticmethod
    def ContFut():
        #! [continuousfuturescontract]
        contract = Contract()
        contract.symbol = "ES"
        contract.secType = "CONTFUT"
        contract.exchange = "GLOBEX"
        #! [continuousfuturescontract]
        return contract

    @staticmethod
    def ContAndExpiringFut():
        #! [contandexpiringfut]
        contract = Contract()
        contract.symbol = "ES"
        contract.secType = "FUT+CONTFUT"
        contract.exchange = "GLOBEX"
        #! [contandexpiringfut]
        return contract

    @staticmethod
    def JefferiesContract():
        #! [jefferies_contract]
        contract = Contract()
        contract.symbol = "AAPL"
        contract.secType = "STK"
        contract.exchange = "JEFFALGO"
        contract.currency = "USD"
        #! [jefferies_contract]
        return contract

    @staticmethod
    def CSFBContract():
        #! [csfb_contract]
        contract = Contract()
        contract.symbol = "IBKR"
        contract.secType = "STK"
        contract.exchange = "CSFBALGO"
        contract.currency = "USD"
        #! [csfb_contract]
        return contract
=end

    end # module

## execute if called from OS
if $0 == __FILE__

mod_methods=  ContractSamples.public_instance_methods 
include ContractSamples
any_contracts =  mod_methods.map do | method |
     self.send( method )
end
puts "Defined Contracts:"
puts "------------------"
puts any_contracts.map.with_index{|x,i| i.to_s + ": " + mod_methods[i][1..-1] + "\t->" + x.to_human }.join( "\n" )


end
