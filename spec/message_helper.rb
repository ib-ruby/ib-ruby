require 'spec_helper'
require 'thread'
require 'stringio'

## Logger helpers

def mock_logger
  @stdout = StringIO.new

  @logger = Logger.new(@stdout).tap do |logger|
    logger.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S.%N')} #{msg}\n"
    end
    logger.level = Logger::DEBUG
  end
end

def log_entries
  @stdout && @stdout.string.split(/\n/)
end

def should_log *patterns
  patterns.each do |pattern|
   expect( log_entries.any? { |entry| entry =~ pattern }).to be_truthy
  end
end

def should_not_log *patterns
  patterns.each do |pattern|
    expect( log_entries.any? { |entry| entry =~ pattern }).to be_falsey
  end
end

## Connection helpers

# Clear logs and message collector. Output may be silenced.
def clean_connection
  if OPTS[:verbose]
    #puts @received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] } if @received
    puts IB::Gateway.tws.received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] }
    puts " Logs:", log_entries if @stdout
  end
  @stdout.string = '' if @stdout
  @ib.clear_received
  @received.clear if @received # In connection_spec
end

def close_connection
  if IB::Gateway.current.present?
    IB::Gateway.current.cancel_order @local_id_placed if  @local_id_placed
    IB::Gateway.current.disconnect if IB::Gateway.current.present?
    clean_connection
  end
end
