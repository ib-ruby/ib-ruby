# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module  Combo
      extend Symbols

			def self.contracts

				@contracts ||= { #super.merge(
					stoxx_straddle: IB::Straddle.build( from: IB::Symbols::Index.stoxx, strike: 3000, 
																					expiry: IB::Symbols::Futures.next_expiry, trading_class: 'OESX') ,
				 stoxx_calendar: IB::Calendar.build( from: IB::Symbols::Index.stoxx, strike: 3000, back: '2m' ,
																					 	expiry: IB::Symbols::Futures.next_expiry, trading_class: 'OESX'),															 
#				 stoxx_butterfly: IB::Butterfly.make( underlying: Symbols::Index.stoxx, strike: 3000, front: 2950, back: 3050 ),
				 stoxx_vertical: IB::Vertical.build( from: IB::Symbols::Index.stoxx, sell: 2500, buy: 3000, right: :put, 
																							expiry: IB::Symbols::Futures.next_expiry, trading_class: 'OESX'),
					zn_calendar: IB::Calendar.fabricate( IB::Symbols::Futures.zn, '3m' ),

				 dbk_straddle: Bag.new( symbol: 'DBK', currency: 'EUR', exchange: 'DTB', combo_legs:
												 [  ComboLeg.new( con_id: 270581032 , action: :buy, exchange: 'DTB', ratio: 1),   #DBK Dez20 2018 C 
													ComboLeg.new( con_id: 270580382,  action: :buy, exchange: 'DTB', ratio: 1 ) ], #DBK Dez 20 2018 P
													 description: 'Option Straddle: Deutsche Bank(20)[Dez 2018]'
																														),
					ib_mcd: Bag.new( symbol: 'IBKR,MCD', currency: 'USD', combo_legs:
											[  ComboLeg.new( con_id: 43645865, action: :buy, ratio: 1), # IKBR STK
												ComboLeg.new( con_id: 9408,	  action: :sell,ratio: 1 ) ], # MCD STK
												description: 'Stock Spread: Buy Interactive Brokers, sell Mc Donalds'
																													 ),

				 vix_calendar:  Bag.new( symbol: 'VIX', currency: 'USD', exchange: 'CFE', combo_legs:
											[  ComboLeg.new( con_id: 256038899, action: :buy, exchange: 'CFE', ratio: 1), #  VIX FUT 201708
												 ComboLeg.new( con_id: 260564703,  action: :sell, exchange: 'CFE', ratio: 1 ) ], # VIX FUT 201709
												description: 'VixFuture  Calendar-Spread August - September 2017'
																													 ),
				 wti_coil: Bag.new( symbol: 'WTI', currency: 'USD', exchange: 'SMART', combo_legs:
										 [  ComboLeg.new( con_id: 55928698, action: :buy, exchange: 'IPE', ratio: 1), #  WTI future June 2017 
												ComboLeg.new( con_id: 55850663,  action: :sell, exchange: 'IPE', ratio: 1 ) ], # COIL future June 2017
											 description: 'Smart Future Spread WTI - COIL (June 2017) '
																													),
				wti_brent:  Bag.new( symbol: 'CL.BZ', currency: 'USD', exchange: 'NYMEX', combo_legs:
										[ ComboLeg.new( con_id: 47207310, action: :buy, exchange: 'NYMEX', ratio: 1), #  CL Dec'16 @NYMEX
											ComboLeg.new( con_id: 47195961,  action: :sell, exchange: 'NYMEX', ratio: 1 ) ],  #BZ Dec'16 @NYMEX
											description: ' WTI - Brent Spread (Dez. 2016)'
																												 )
				}
			#	)
			end

		end
	end
end
