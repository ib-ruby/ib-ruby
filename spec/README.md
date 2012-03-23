# WRITING INTEGRATION SPECS

Pattern for writing integration specs is like this:

1. You define your user scenario (such as: subscribe for FUTURES market data).

2. You find out experimentally, what messages should be sent to IB to accomplish it,
   and what messages are sent by IB in return.

3. You start writing spec, requiring 'integration_helper'. Don't forget to
   'verify_account'! Running tests against live IB account can be pretty painful.

4. Establish connection in a top-level before(:all) block. Wait for IB to deliver
   initial messages/data, for example using '@ib.wait_for :NextValidId' idiom.

5. Now, you set up your context and send appropriate request messages to IB. Once
   messages are sent, you need to give the server time to respond. The proper way
   to do it is by '@ib.wait_for' specific message type that indicates that your
   request was answered. For example, if you send :RequestOpenOrders, then received
   :OpenOrdersEnd will be a sign that your request was processed. Usually, you
   wait_for in a context before(:all) block.

6. It is now time to examine what responses you've got from IB and see if they meet
   your expectations. All messages received frem IB are caught and placed into
   @ib.received Hash, keyed by message type. The Hash has following structure:
   {:MessageType1 => [msg1, msg2, msg3...], :MessageType2 => [msg1, msg2, msg3...] }.

7. If you created @ib Connection with mock_logger, all log entries produced by IB
   will be also caught and placed into log_entries Array.

8. Your examples can thus test the content of @ib.received Hash to see what messages
   were received, or log_entries Array to see what was logged.

9. When done with this context, you call 'close_connection' helper in a top-level
   after(:all) block to get rid of your active connection.

10. If you reuse the connection between contexts and requests, it is recommended to
   call 'clean_connection' in after block to remove old content from @ib.received Hash,
   or otherwise manually clean it to remove old/not needed messages from it.

Help the development!
See 'spec/TODO' file for list of scenarios that still need to be tested.
