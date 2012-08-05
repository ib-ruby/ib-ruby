## RUNNING TEST SUITE:

The gem comes with a spec suite that may be used to test ib-ruby compatibility
with your specific TWS/Gateway installation. The test suite should be run ONLY
against your IB paper trading account. Running it against live account may result
in financial losses.

In order to run tests, you should set up your IB paper trading connection parameters
in 'spec/spec_helper' file. Modify account_name, host and port under section
'Your IB PAPER ACCOUNT'. Do not change the client_id.

Before running tests, you need to start your TWS/Gateway and allow API connection.
You should not have any open/pending orders on your IB paper trading account prior
to running tests, otherwise some tests will fail. Use 'bin/cancel_orders' script for
bulk cancelling of open orders before running tests as needed.

By default, specs suppress logging output that is normally produced by IB::Connection.
This may make it difficult to debug a failing spec. The following option will switch on verbose
output (both logger output and content of all received IB messages is dumped). Do not use
this mode to run a whole spec - you will be swamped! Use it to debug specific failing specs
only:

    $ rspec -rv [spec/specific_spec.rb]

By default, specs are run without database support (tableless). In order to run them
with database backend, use:

    $ rspec -rdb [spec/specific_spec.rb]

If you run your specs against both Gateway and TWS, you may want to use the following
switches (by default, TWS port is used):

    $ rspec -rgw [spec/specific_spec.rb]
    $ rspec -rtws [spec/specific_spec.rb]

## RUNNING RAILS-SPECIFIC SPECS:

This gem has two operating modes: standalone and Rails-engine. If you require it in a
Rails environment, it loads Rails engine automatically. Otherwise, it does not load any
Rails integration. So, Rails-specific specs are separated from generic spec suite and
located in 'rails_spec'. 

There are two included Rails apps that can be used to test engine integration. One is
an auto-generated Dummy app, and another is [Combustion](https://github.com/freelancing-god/combustion) based.

To test Rails engine integration with Combustion-based Rails application, use:

    $ rspec -rcomb rails_spec
    $ rspec -rcomb [spec/specific_spec.rb]

To run specs with Dummy Rails application, use:

    $ rspec -rdummy rails_spec
    $ rspec -rdummy [spec/specific_spec.rb]

Other suite switches described in previous section should work with Rails as well.    

## PROBLEMS WHILE RUNNING THE SPECS:

Some of the specs may randomly fail from time to time when you are running the spec suite 
against your IB paper account. This happens because these specs depend on live connection
to IB, which is inherently non-deterministic. Anything happening along the way - network
delay, problems with IB data farms, even high CPU load on your machine - may delay the
expected response, so that the spec times out or does not find expected data. For example,
IB historical data farm is known to disappear from time to time, so any specs related to
historical data will fail while this outage lasts. 

If you experience such intermittent spec failures, it is recommended that you run the 
failing specs several times, possibly with a delay of 10-20 minutes. Sometimes it helps
to restart your TWS or Gateway, as it may be stuck in inconsistent state, preventing
test suite from running properly. Start debugging the specs only if they are failing 
regularly. Otherwise, you may just waste time chasing an artifact of unreliable IB 
connection, rather than some real problem with the specs.   

# WRITING YOUR OWN INTEGRATION SPECS

You can easily create your own integration specs. Pattern for writing specs is like this:

1. You define your user scenario (such as: subscribe to FUTURES market data).

2. You find out from documentation or experimentally, what messages should be sent to
   IB to accomplish it, and what messages are sent by IB in return.

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
   your expectations. All messages received from IB are caught and placed into
   @ib.received Hash, keyed by message type. The Hash has following structure:
   {:MessageType1 => [msg1, msg2, msg3...], :MessageType2 => [msg1, msg2, msg3...] }.

7. If you created @ib Connection with a mock_logger, all log entries produced by IB
   will be also caught and placed into log_entries Array.

8. Your examples can thus check the content of @ib.received Hash to see what messages
   were received, or log_entries Array to see what was logged.

9. When done with this context, you call 'close_connection' helper in a top-level
   after(:all) block to get rid of your active connection.

10. If you reuse the connection between contexts and requests, it is recommended to
   call 'clean_connection' in after block to remove old content from @ib.received Hash,
   and log_entries Array or otherwise manually clean them to remove old/not needed
   messages from and log entries. If your do not do this, your examples become coupled.

11. If you want to see exactly what's going on inside ib-ruby while your examples are
    running, run your specs with '-rv' option to switch on verbose output mode.
    Now you will see all the messages received and log entries made as as result of
    your examples running. Be warned, output is very verbose, so don't run big chunk of
    specs with -rv option or you will be swamped!.

Help the development!
See 'spec/TODO' file for list of scenarios that still need to be tested.
