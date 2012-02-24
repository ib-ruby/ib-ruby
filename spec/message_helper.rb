require 'spec_helper'
require 'thread'
require 'stringio'

def print_subject
  it 'prints out message' do
    p subject
    p subject.to_human
  end
end

alias ps print_subject

## Logger helpers

def mock_logger
  @stdout = StringIO.new

  @logger = Logger.new(@stdout).tap do |logger|
    logger.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S.%N')} #{msg}\n"
    end
    logger.level = Logger::INFO
  end
end

def log_entries
  @stdout && @stdout.string.split(/\n/)
end

def should_log *patterns
  patterns.each do |pattern|
    log_entries.any? { |entry| entry =~ pattern }.should be_true
  end
end

def should_not_log *patterns
  patterns.each do |pattern|
    log_entries.any? { |entry| entry =~ pattern }.should be_false
  end
end

## Connection helpers

def connect_and_receive *message_types

  # Start disconnected (we need to set up catch-all subscriber first)
  @ib = IB::Connection.new CONNECTION_OPTS.merge(:connect => false,
                                                 :reader => false,
                                                 :logger => mock_logger)

  # Hash of received messages, keyed by message type
  @received = Hash.new { |hash, key| hash[key] = Array.new }

  # Catch all messages of given types and put them inside @received Hash
  @ib.subscribe(*message_types) { |msg| @received[msg.message_type] << msg }

  @ib.connect
  @ib.start_reader
end

# Clear logs and message collector. Output may be silenced
def clean_connection
  unless SILENT
    puts @received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] }
    puts " Logs:"
    puts log_entries
  end
  @stdout.string = '' if @stdout
  @received.clear if @received
end

def close_connection
  @ib.close if @ib
  clean_connection
end

#noinspection RubyArgCount
def wait_for time = 2, &condition
  timeout = Time.now + time
  sleep 0.1 until timeout < Time.now || condition && condition.call
end

def received? symbol
  not @received[symbol].empty?
end

# Make sure integration tests are only run against the pre-configured PAPER ACCOUNT
def verify_account
  account = CONNECTION_OPTS[:account] || CONNECTION_OPTS[:account_name]
  raise "Please configure IB PAPER ACCOUNT in spec/spec_helper.rb" unless account

  connect_and_receive :AccountValue
  @ib.send_message :RequestAccountData, :subscribe => true

  wait_for { received? :AccountValue }
  raise "Unable to verify IB PAPER ACCOUNT" unless received? :AccountValue

  received = @received[:AccountValue].first.data[:account_name]
  raise "Connected to wrong account #{received}, expected #{account}" if account != received

  close_connection
end

verify_account
