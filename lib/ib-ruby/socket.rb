require 'socket'

module IB
  class IBSocket < TCPSocket

    # send nice null terminated binary data into socket
    def send data
      self.syswrite(data.to_s + EOL)
    end

    def read_string
      string = self.gets(EOL)

      until string
        # Silently ignores nils
        string = self.gets(EOL)
        sleep 0.1
      end

      string.chop
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
      str.to_f unless str.nil? || str.empty? || str.to_f > 1.797 * 10.0 ** 306
    end
  end # class IBSocket

end # module IB
