#!/usr/bin/env ruby -w
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

$:.push(File.dirname(__FILE__) + "/../")

require 'test/unit'
require 'ib'
require 'datatypes'

class ContractTests < Test::Unit::TestCase
  def test_plain_instantiation
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new
      assert_not_nil(x)
    }
  end
  
  def test_sec_type_filter
    assert_raise(ArgumentError) {
      x = IB::Datatypes::Contract.new({:sec_type => "asdf"})
    }
    
    assert_raise(ArgumentError) {
      x = IB::Datatypes::Contract.new
      x.sec_type = "asdf"
    }
    
    IB::Datatypes::Contract::SECURITY_TYPES.values.each {|type|
      assert_nothing_raised {
        x = IB::Datatypes::Contract.new({:sec_type => type })
      }
      assert_nothing_raised {
        x = IB::Datatypes::Contract.new
        x.sec_type = type
      }
    }
  end
  
  def test_expiry
    assert_raise(ArgumentError) {
      x = IB::Datatypes::Contract.new({:expiry => "foo" })
    }
    assert_raise(ArgumentError) {
      x = IB::Datatypes::Contract.new
      x.expiry = "foo"
    }
    
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:expiry => "200607" })
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new
      x.expiry = "200607"
    }    
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:expiry => 200607 })
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new
      x.expiry = 200607
      assert_equal(x.expiry, "200607") # converted to a string
    }    

  end

  def test_right
    assert_raise(ArgumentError) {
      x = IB::Datatypes::Contract.new({:right => "foo" })
    }
    assert_raise(ArgumentError) {
      x = IB::Datatypes::Contract.new
      x.right = "foo"
    }
    
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "PUT"})
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "put"})
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "call"})
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "CALL"})
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "P"})
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "p"})
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "c"})
    }
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new({:right => "C"})
    }

    assert_nothing_raised {
      x = IB::Datatypes::Contract.new
      x.right = "put"
    }    

  end
  
  def test_serialize_long
    x = nil
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new
      x.symbol = "TEST"
      x.sec_type = IB::Datatypes::Contract::SECURITY_TYPES[:stock]
      x.expiry = 200609
      x.strike = 1234
      x.right = "put"
      x.multiplier = 123
      x.exchange = "SMART"
      x.currency = "USD"
      x.local_symbol = "baz"
    }
    
    assert_equal(["TEST", IB::Datatypes::Contract::SECURITY_TYPES[:stock], "200609", 1234, "PUT", 123, "SMART", nil, "USD", "baz"], 
                 x.serialize_long(20))
  end # test_serialize_long
  
  def test_serialize_short
    x = nil
    assert_nothing_raised {
      x = IB::Datatypes::Contract.new
      x.symbol = "TEST"
      x.sec_type = IB::Datatypes::Contract::SECURITY_TYPES[:stock]
      x.expiry = 200609
      x.strike = 1234
      x.right = "put"
      x.multiplier = 123
      x.exchange = "SMART"
      x.currency = "USD"
      x.local_symbol = "baz"
    }
    
    assert_equal(["TEST", IB::Datatypes::Contract::SECURITY_TYPES[:stock], "200609", 1234, "PUT", 123, "SMART", "USD", "baz"], 
                 x.serialize_short(20))
  end # test_serialize_short

end # ContractTests
