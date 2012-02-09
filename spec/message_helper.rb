require 'spec_helper'
require 'thread'

# TODO: Hack in Logger

def message_type msg
  msg.class.to_s.split(/::/).last.to_sym
end

def wait_for time = 1, &condition
  timeout = Time.now + time
  sleep 0.1 until timeout < Time.now || condition && condition.call()
end

def connect_and_receive *message_types
  # Start disconnected (we need to set up catch-all subscriber first)
  @ib = IB::Connection.new CONNECTION_OPTS.merge(:connect => false, :reader => false)

  # Hash of received messages, keyed by message type
  @received = Hash.new { |hash, key| hash[key] = Array.new }

  # Catch all messages of given types and put them inside @received Hash
  @ib.subscribe(*message_types) { |msg| @received[message_type(msg)] << msg }

  @ib.connect
  @ib.start_reader
end

