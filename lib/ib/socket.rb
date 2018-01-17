require 'socket'
module IBSupport
  refine  Array do
    def tws
      if blank?
	nil.tws
      else
	self.flatten.map( &:tws ).join  # [ "", [] , nil].flatten -> ["", nil]
					# elemets with empty array's are cut 
					# this is the desired behavior!
      end
    end
  end
  refine  Symbol do
    def tws
      self.to_s.tws
    end
  end
  refine String do
    def tws
      if empty?
	IB::EOL
      else
	self[-1] == IB::EOL ? self : self+IB::EOL
      end
    end
  end

  refine  Numeric do
    def tws
      self.to_s.tws
    end
  end

  refine TrueClass do
    def tws
      1.tws
    end
  end

  refine  FalseClass do
    def tws
      0.tws
    end
  end

  refine NilClass do
    def tws
     IB::EOL
    end
  end
end
module IB
  module PrepareData

    using IBSupport
    def prepare_message data
      data =  data.tws unless data.is_a?(String) && data[-1]== EOL
      matrize = [data.size,data]
      if block_given?	    # A user defined decoding-sequence is accepted via block
	matrize.pack yield
      else
	matrize.pack  "Na*"
      end
    end

    def decode_message msg
      m = Hash.new
      while not msg.blank?
	# the first item is the length
	size= msg[0..4].unpack("N").first
	msg =  msg[4..-1]
	# followed by a sequence of characters
	message =  msg.unpack("A#{size}").first.split("\0")
	if block_given?
	  yield message
	else
	  m[message.shift.to_i] = message
	end
	msg =  msg[size..-1]
      end
      return m unless block_given?
      end
    
  end

  class IBSocket < TCPSocket
    include PrepareData
    using IBSupport

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


    def read_string
      string = self.gets(EOL)

      until string
	# Silently ignores nils
	string = self.gets(EOL)
	sleep 0.1
      end

      string.chop
    end


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
	# STDOUT.puts "BUFFER:: #{buffer.inspect}"
	  complete_message_buffer << buffer

	end while buffer.size == 4096
	complete_message_buffer.join('')
      rescue Errno::ECONNRESET =>  e
	IB::Connection.logger.error{ "Data Buffer is not filling \n
		    The Buffer: #{buffer.inspect} \n
		    Backtrace:\n 
	 #{e.backtrace.join("\n") } " }
	Kernel.exit
      end
    end

    ### Complex operations

#    # Returns loaded Array or [] if count was 0
#    def read_array &block
#      count = read_int
#      count > 0 ? Array.new(count, &block) : []
#    end
#
#    # Returns loaded Hash
#    def read_hash
#      tags = read_array { |_| [read_string, read_string] }
#      tags.empty? ? Hash.new : Hash[*tags.flatten]
#    end
#
  end # class IBSocket

end # module IB
