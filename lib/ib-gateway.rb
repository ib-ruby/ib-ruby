module IB
  def self.db_backed?
    !!defined?(IB::DB)
  end
end
Ib = IB

  require 'ib/requires'
	require 'ib/gw_requires'
