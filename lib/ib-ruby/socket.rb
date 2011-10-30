require 'socket'

module IB
  class IBSocket < TCPSocket

    # send nice null terminated binary data into socket
    def send data
      self.syswrite(data.to_s + EOL)
    end

    def read_string
      self.gets(EOL).chop
    end

    def read_int
      self.read_string.to_i
    end

    def read_int_max
      str = self.read_string
      str.nil? || str.empty? ? nil : str.to_i
    end

    def read_boolean
      self.read_string.to_i != 0
    end

    def read_decimal
      # Floating-point numbers shouldn't be used to store money...
      # ...but BigDecimals are too unwieldy to use in this case... maybe later
      #  self.read_string.to_d
      self.read_string.to_f
    end

    def read_decimal_max
      str = self.read_string
      # Floating-point numbers shouldn't be used to store money...
      # ...but BigDecimals are too unwieldy to use in this case... maybe later
      #  str.nil? || str.empty? ? nil : str.to_d
      str.nil? || str.empty? ? nil : str.to_f
    end
  end # class IBSocket

end # module IB
