module IB

  # Error handling
  class Error < StandardError
  end

  class ArgumentError < ArgumentError
  end

end # module IB

### Patching Object with universally accessible top level error method
def error message, type=:standard
  case type
    when :standard
      raise IB::Error.new message
    when :args
      raise IB::ArgumentError.new message
  end
end

