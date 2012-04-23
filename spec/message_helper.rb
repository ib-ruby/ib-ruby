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

# Clear logs and message collector. Output may be silenced.
def clean_connection
  if OPTS[:verbose]
    #puts @received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] } if @received
    puts @ib.received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] }
    puts " Logs:", log_entries if @stdout
  end
  @stdout.string = '' if @stdout
  @ib.clear_received
  @received.clear if @received # In connection_spec
end

def close_connection
  @ib.cancel_order @local_id_placed if @ib && @local_id_placed
  @ib.close if @ib
  clean_connection
end
