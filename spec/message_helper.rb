require 'spec_helper'
require 'thread'

# TODO: Hack in Logger

def message_type msg
  msg.class.to_s.split(/::/).last.to_sym
end

def wait_for time, &condition
  timeout = Time.now + time
  sleep 0.1 until timeout < Time.now || condition && condition.call()
end

def connect_and_receive *message_types
  # Start unconnected to set up catch-all subscriber first
  @ib = IB::Connection.new CONNECTION_OPTS.merge(:connect => false, :reader => false)

  # Hash of received messages, keyed by message type
  @received = Hash.new { |hash, key| hash[key] = Array.new }

  @ib.subscribe(*message_types) do |msg|
    #puts msg.to_human
    #p message_type(msg)
    @received[message_type(msg)] << msg
  end

  @ib.connect
  @ib.start_reader
end

