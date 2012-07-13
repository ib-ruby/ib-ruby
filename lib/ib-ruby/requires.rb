module IB

  def self.db_backed?
    !!defined?(IB::DB)
  end

  require 'ib-ruby/version'
  require 'ib-ruby/extensions'
  require 'ib-ruby/errors'
  require 'ib-ruby/constants'
  require 'ib-ruby/connection'

  require 'ib-ruby/models'
  require 'ib-ruby/messages'
  require 'ib-ruby/symbols'
end
