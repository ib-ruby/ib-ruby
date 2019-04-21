#
# Where is TWS or IB gateway started?
# Define the host IP and port in this file.
#
# TWS per default uses port 7496, newer versions
# use port 7497. Gateway is per default on port
# 4001, newer versions on 4002.
#

$host = ENV['IBHOST'] || '127.0.0.1'
$port = ENV['IBPORT'] || 7496

