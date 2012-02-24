# WRITING INTEGRATION SPECS

Pattern for writing integration specs is like this:

1. You define your user scenario (such as: subscribe for FOREX market data).

2. You find out experimentally, what messages should be sent to IB to accomplish it,
   and what messages are sent by IB in return.

3. You start writing spec, requiring 'integration_helper'.

4. Indicate your interest in incoming message types by calling 'connect_and_receive'
   in a top-level before(:all) block. All messages of given types will be caught
   and placed into @received Hash, keyed by message type.

5. All log entries produced by ib-ruby will be caught and placed into log_entries Array.

6. You send request messages to IB and then wait for specific conditions (or timeout)
   by calling 'wait_for' (usually, in a context before(:all) block).

7. Once the conditions are satisfied, your examples can test the content of @received
   Hash to see what messages were received, or log_entries Array to see what was logged

8. When done, you call 'close_connection' in a top-level  after(:all) block.

