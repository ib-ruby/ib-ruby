#
# Copyright (C) 2006 Blue Voodoo Magic LLC.
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA
#

#
# Note that the :description field is particular to ib-ruby, and is NOT part of the standard TWS API.
# It is never transmitted to IB. It's purely used clientside, and you can store any arbitrary string that
# you may find useful there.
#

$:.push(File.dirname(__FILE__) + "/../")

require 'ib'
require 'datatypes'

module IB
  module Symbols
    Forex = 
     {
      :gbpusd => Datatypes::Contract.new({
                                           :symbol => "GBP",
                                           :exchange => "IDEALPRO",
                                           :currency => "USD",
                                           :sec_type => Datatypes::Contract::SECURITY_TYPES[:forex],
                                           :description => "GBPUSD"
                                           
                                         }),
      :eurusd => Datatypes::Contract.new({
                                           :symbol => "EUR",
                                           :exchange => "IDEALPRO",
                                           :currency => "USD",
                                           :sec_type => Datatypes::Contract::SECURITY_TYPES[:forex],
                                           :description => "EURUSD"

                                         }),
      :usdjpy => Datatypes::Contract.new({
                                           :symbol => "USD",
                                           :exchange => "IDEALPRO",
                                           :currency => "JPY",
                                           :sec_type => Datatypes::Contract::SECURITY_TYPES[:forex],
                                           :description => "USDJPY"

                                         })

     } 
  end # Contracts
end
