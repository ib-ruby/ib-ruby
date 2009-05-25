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

# These futures will likely have expired by the time you read this, but they can serve as examples.
# TODO: auto-generate a front-month contract object.
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
    Futures =
     {
      :es => Datatypes::Contract.new({
                                       :symbol => "ES",
                                       :expiry => "200809", # <---- Change this date!!
                                       :exchange => "GLOBEX",
                                       :currency => "USD",
                                       :sec_type => Datatypes::Contract::SECURITY_TYPES[:future],
                                       :multiplier => 50,
                                       :description => "E-Mini S&P 500"
                                     }),

      :gbp => Datatypes::Contract.new({
                                       :symbol => "GBP",
                                       :expiry => "200809", # <---- Change this date!!
                                       :exchange => "GLOBEX",
                                       :currency => "USD",
                                       :sec_type => Datatypes::Contract::SECURITY_TYPES[:future],
                                       :multiplier => 62500,
                                       :description => "British Pounds"
                                     }),
      :eur => Datatypes::Contract.new({
                                       :symbol => "EUR",
                                       :expiry => "200809", # <---- Change this date!!
                                       :exchange => "GLOBEX",
                                       :currency => "USD",
                                       :sec_type => Datatypes::Contract::SECURITY_TYPES[:future],
                                       :multiplier => 12500,
                                       :description => "Euro FX"
                                     }),
      :jpy => Datatypes::Contract.new({
                                       :symbol => "JPY",
                                       :expiry => "200809", # <---- Change this date!!
                                       :exchange => "GLOBEX",
                                       :currency => "USD",
                                       :sec_type => Datatypes::Contract::SECURITY_TYPES[:future],
                                       :multiplier => 12500000,
                                       :description => "Japanese Yen"
                                     }),
      :hsi => Datatypes::Contract.new({
                                       :symbol => "HSI",
                                       :expiry => "200808", # <---- Change this date!!
                                       :exchange => "HKFE",
                                       :currency => "HKD",
                                       :sec_type => Datatypes::Contract::SECURITY_TYPES[:future],
                                       :multiplier => 50,
                                       :description => "Hang Seng Index"
                                     })
    }
  end
end
