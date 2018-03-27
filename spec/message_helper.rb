require 'spec_helper'
require 'thread'
require 'stringio'
require 'rspec/expectations'

## Logger helpers

def mock_logger
  @stdout = StringIO.new

  @logger = Logger.new(@stdout).tap do |logger|
    logger.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S')} #{msg}\n"
    end
    logger.level = Logger::INFO
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
	ib =  IB::Connection.current
  if OPTS[:verbose]
    #puts @received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] } if @received
    puts ib.received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] }
    puts " Logs:", log_entries if @stdout
  end
  @stdout.string = '' if @stdout
  ib.clear_received if ib
  @received.clear if @received # In connection_spec
end

def close_connection
	ib =  IB::Connection.current
	#  don't cancel orders after finishing tests, 
	#  otherwise it's not possible to inspect them manually, in case something went wrong
#  ib.cancel_order @local_id_placed if ib && @local_id_placed
  clean_connection
  ib.close if ib
end
