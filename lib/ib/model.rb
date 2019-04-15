## Connection to Orientdb is established if the oriendb-client is
# present upon require if ib-ruby
# If ActiveOrient is not connected (ActiveOrient::Init.connect has not been called)
# lightweigth tables are used
require 'ib/base_properties'
#require 'active-orient'
#if ActiveOrient::Model.orientdb.nil?
require 'ib/base'
	IB::Model = IB::Base
#else
#	require 'ib/orientdb'
#	IB::Model =  V #ActiveOrient::Base
#	IB::DB.connect
#	puts " IB-Ruby is run in OrientDB-Mode"
#end
#module IB
  # IB Models can be either lightweight (tableless) or database-backed.
  # require 'ib/db' - to make all IB models database-backed
#  Model =  IB.db_backed? ? ActiveRecord::Base : IB::Base
#end
