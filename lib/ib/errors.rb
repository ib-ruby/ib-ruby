module IB

  # Error handling
  class Error < RuntimeError
  end

  class ArgumentError < ArgumentError
  end

  class SymbolError < ArgumentError
  end

  class LoadError < LoadError
  end

  class FlexError < RuntimeError
  end

  class TransmissionError < RuntimeError
  end
end # module IB

# Patching Object with universally accessible top level error method. 
# The method is used throughout the lib instead of plainly raising exceptions. 
# This allows lib user to easily inject user-specific error handling into the lib 
# by just replacing Object#error method.
def error message, type=:standard, backtrace=nil
  e = case type
  when :standard
    IB::Error.new message
  when :args
    IB::ArgumentError.new message
  when :symbol
    IB::SymbolError.new message
  when :load
    IB::LoadError.new message
  when :flex
    IB::FlexError.new message
  when :reader
    IB::TransmissionError.new message
  end
  e.set_backtrace(backtrace) if backtrace
  raise e
end
