# WRITING MESSAGE SPECS

Pattern for writing message specs is like this:

1. You indicate your interest in some message types by calling 'connect_and_receive'
   in a top-level before(:all) block. All messages of given types will be caught
   and placed into @received Hash, keyed by message type

2. You send request messages to IB and then wait for specific conditions (or timeout)
   by calling 'wait_for' in a context before(:all) block.

3. Once the condition is satisfied, you can test the content of @received Hash
   to see what messages were received, or log_entries Array to see what was logged

4. When done, you call 'close_connection' in a top-level  after(:all) block.

