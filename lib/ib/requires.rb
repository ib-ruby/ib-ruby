module IB
  def self.db_backed?
    !!defined?(IB::DB)
  end
end

require 'ib/version'
require 'ib/extensions'
require 'ib/errors'
require 'ib/constants'
require 'ib/connection'

require 'ib/models'
require 'ib/messages'
require 'ib/symbols'
