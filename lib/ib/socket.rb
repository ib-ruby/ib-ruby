require 'socket'
class Array
  def tws
    self.map( &:tws ).join
  end
end
class Symbol
  def tws
    self.to_s.tws
  end
end
class String
  def tws
    self[-1] == IB::EOL ? self : self+IB::EOL
  end
end

class  Numeric
  def tws
    self.to_s.tws
  end
end

class TrueClass
  def tws
    1.tws
  end
end

class FalseClass
  def tws
    0.tws
  end
end

class NilClass
  def tws
    0.tws
  end
end
module IB
  module PrepareData

    def prepare_message data
      data =  data.tws unless data.is_a?(String) && data[-1]== EOL
      matrize = [data.size,data]
      if block_given?
	matrize.pack yield
      else
	matrize.pack  "Na*"
      end
    end

    def decode_message msg
      unless msg.blank?
      size= msg[0..4].unpack("N").first
      message =  msg[4..-1].unpack("A#{size}").first.split("\0")
      else
	error "cannot decode an empty message"
	""
      end
    end
  end

  class IBSocket < TCPSocket
    include PrepareData

    def initialising_handshake
      v100_prefix = "API".tws.encode 'ascii' 
      v100_version = self.prepare_message Messages::SERVER_VERSION
      write_data v100_prefix+v100_version
    end
    ## start tws-log
    # [QO] INFO  [JTS-SocketListener-49] - State: HEADER, IsAPI: UNKNOWN
    # [QO] INFO  [JTS-SocketListener-49] - State: STOP, IsAPI: YES
    # [QO] INFO  [JTS-SocketListener-49] - ArEServer: Adding 392382055 with id 2147483647
    # [QO] INFO  [JTS-SocketListener-49] - eServersChanged: 1
    # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] Starting new conversation with client on 127.0.0.1
    # [QO] INFO  [JTS-EServerSocketNotifier-288] - Starting async queue thread
    # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] Server version is 136
    # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] Client version is 136
    # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] is 3rdParty true
    ## end tws-log

    # Sends null terminated data string into socket
    def write_data data
      self.syswrite data.tws
    end

    # send the message (containing several instructions) to the socket,
    # calls prepare_message to convert data-elements into NULL-terminated strings
    def send_messages *data
      self.syswrite prepare_message(data)
    rescue Errno::ECONNRESET =>  e
      logger.error{ "Data not accepted by IB \n
		    #{data.inspect} \n
		    Backtrace:\n "}
      logger.error   e.backtrace
    end
  
    def recieve_messages
      begin
      complete_message_buffer = []
      begin 
	# this is the blocking version of recv
	buffer =  self.recvfrom(4096)[0]
	complete_message_buffer << buffer

      end while buffer.size == 4096
      complete_message_buffer.join('')
    rescue Errno::ECONNRESET =>  e
      logger.error{ "Data Buffer is not filling \n
		    The Buffer: #{buffer.inspect} \n
		    Backtrace:\n "}
      logger.error   e.backtrace
      Kernel.exit
    end
    end

 #def _recvAllMsg(self):
 #  109         cont = True
 #  110         allbuf = b""
 #  111 
 #  112         while cont:
 #    113             buf = self.socket.recv(4096)
 #  114             allbuf += buf
 #  115             logging.debug("len %d raw:%s|", len(buf), buf)
 #  116 
 #  117             if len(buf) < 4096:
 #    118                 cont = False
 #  119 
 #  120         return allbuf

 #end

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
      str.to_i unless str.nil? || str.empty?
    end

    def read_boolean
      str = self.read_string
      str.nil? ? false : str.to_i != 0
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

    # If received decimal is below limit ("not yet computed"), return nil
    def read_decimal_limit limit = -1
      value = self.read_decimal
      # limit is the "not yet computed" indicator
      value <= limit ? nil : value
    end

    alias read_decimal_limit_1 read_decimal_limit

    def read_decimal_limit_2
      read_decimal_limit -2
    end

    ### Complex operations

    # Returns loaded Array or [] if count was 0
    def read_array &block
      count = read_int
      count > 0 ? Array.new(count, &block) : []
    end

    # Returns loaded Hash
    def read_hash
      tags = read_array { |_| [read_string, read_string] }
      tags.empty? ? Hash.new : Hash[*tags.flatten]
    end

  end # class IBSocket

end # module IB
