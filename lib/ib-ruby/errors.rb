module IB

  # Error handling
  class Error < RuntimeError
  end

  class ArgumentError < ArgumentError
  end

  class LoadError < LoadError
  end

end # module IB

### Patching Object with universally accessible top level error method
def error message, type=:standard, backtrace=nil
  e = case type
        when :standard
          IB::Error.new message
        when :args
          IB::ArgumentError.new message
        when :load
          IB::LoadError.new message
      end
  e.set_backtrace(backtrace) if backtrace
  raise e
end

