#
# Copyright (C) 2006 Blue Voodoo Magic LLC.
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA
#

require 'sha1'
require 'socket'
require 'logger'
require 'bigdecimal'
require 'bigdecimal/util'

require 'messages'
require 'iblogger'


# Add method to_ib to render datetime in IB format (zero padded "yyyymmdd HH:mm:ss")
class Time
  def to_ib
    "#{self.year}#{sprintf("%02d", self.month)}#{sprintf("%02d", self.day)} " +
    "#{sprintf("%02d", self.hour)}:#{sprintf("%02d", self.min)}:#{sprintf("%02d", self.sec)}"
  end
end # Time


module IB

  TWS_IP_ADDRESS = "127.0.0.1"
  TWS_PORT = "7496"


  class IBSocket < TCPSocket

    # send nice null terminated binary data
    def send(data)
      self.syswrite(data.to_s + "\0")
    end

    def read_string
      self.gets("\0").chop
    end

    def read_int
      self.read_string.to_i
    end

    def read_boolean
      self.read_string.to_i != 0
    end

    # Floating-point numbers shouldn't be used to store money.
    def read_decimal
      self.read_string.to_d
    end

  end # class IBSocket



  class IB
    Tws_client_version = 27

    attr_reader :next_order_id

    def initialize(options_in = {})
      @options = {
        :ip => TWS_IP_ADDRESS,
        :port => TWS_PORT,
      }.merge(options_in)

      @connected = false
      @next_order_id = nil
      @server = Hash.new # information about server and server connection state

      # Message listeners.
      # Key is the message class to listen for.
      # Value is an Array of Procs. The proc will be called with the populated message instance as its argument when
      # a message of that type is received.
      @listeners = Hash.new { |hash, key|
        hash[key] = Array.new
      }


      IBLogger.debug("IB#init: Initializing...")

      self.open(@options)

    end # init

    def server_version
      @server[:version]
    end


    def open(options_in = {})
      raise Exception.new("Already connected!") if @connected

      opts = {
        :ip => "127.0.0.1",
        :port => "7496"
      }.merge(options_in)


      # Subscribe to the NextValidID message from TWS that is always
      # sent at connect, and save the id.
      self.subscribe(IncomingMessages::NextValidID, lambda {|msg|
                       @next_order_id = msg.data[:order_id]
                       IBLogger.info { "Got next valid order id #{@next_order_id}." }
                     })

      @server[:socket] = IBSocket.open(@options[:ip], @options[:port])
      IBLogger.info("* TWS socket connected to #{@options[:ip]}:#{@options[:port]}.")

      # Sekrit handshake.
      IBLogger.debug("\tSending client version #{Tws_client_version}..")

      @server[:socket].send(Tws_client_version)
      @server[:version] = @server[:socket].read_int
      @@server_version = @server[:version]
      @server[:local_connect_time] = Time.now()

      IBLogger.debug("\tGot server version: #{@server[:version]}.")

      # Server version >= 20 sends the server time back.
      if @server[:version] >= 20
        @server[:remote_connect_time] = @server[:socket].read_string
        IBLogger.debug("\tServer connect time: #{@server[:remote_connect_time]}.")
      end

      # Server version >= 3 wants an arbitrary client ID at this point. This can be used
      # to identify subsequent communications.
      if @server[:version] >= 3
        @server[:client_id] = SHA1.digest(Time.now.to_s + $$.to_s).unpack("C*").join.to_i % 999999999
        @server[:socket].send(@server[:client_id])
        IBLogger.debug("\tSent client id # #{@server[:client_id]}.")
      end

      IBLogger.debug("Starting reader thread..")
      Thread.abort_on_exception = true
      @server[:reader_thread] = Thread.new {
        self.reader
      }

      @connected = true
    end



    def close
      @server[:reader_thread].kill # Thread uses blocking I/O, so join is useless.
      @server[:socket].close()
      @server = Hash.new
      @@server_version = nil
      @connected = false
      IBLogger.debug("Disconnected.")
    end # close



    def to_s
      "IB Connector: #{ @connected ? "connected." : "disconnected."}"
    end



    # Subscribe to incoming message events of type messageClass.
    # code is a Proc that will be called with the message instance as its argument.
    def subscribe(messageClass, code)
      raise(Exception.new("Invalid argument type (#{messageClass}, #{code.class}) - " +
                          " must be (IncomingMessages::AbstractMessage, Proc)")) unless
        messageClass <= IncomingMessages::AbstractMessage && code.is_a?(Proc)

      @listeners[messageClass].push(code)
    end



    # Send an outgoing message.
    def dispatch(message)
      raise Exception.new("dispatch() must be given an OutgoingMessages::AbstractMessage subclass") unless
        message.is_a?(OutgoingMessages::AbstractMessage)

      IBLogger.info("Sending message " + message.inspect)
      message.send(@server)
    end



    protected

    def reader
      IBLogger.debug("Reader started.")

      while true
        msg_id = @server[:socket].read_int # this blocks, so Thread#join is useless.
        IBLogger.debug {
          "Reader: got message id #{msg_id}.\n"
        }

        # create a new instance of the appropriate message type, and have it read the message.
        msg = IncomingMessages::Table[msg_id].new(@server[:socket], @server[:version])

        @listeners[msg.class].each { |listener|
          listener.call(msg)
        }

        IBLogger.debug {
          " Listeners: " + @listeners.inspect + " inclusion: #{ @listeners.include?(msg.class)}"
        }


        # Log the message if it's an error.
        # Make an exception for the "successfully connected" messages, which, for some reason, come back from IB as errors.
        if msg.is_a?(IncomingMessages::Error)
          if msg.code == 2104 || msg.code == 2106 # connect strings
            IBLogger.info(msg.to_human)
          else
            IBLogger.error(msg.to_human)
          end
        else
          # Warn if nobody listened to a non-error incoming message.
          unless @listeners[msg.class].size > 0
            IBLogger.warn { " WARNING: Nobody listened to incoming message #{msg.class}" }
          end
        end


        # IBLogger.debug("Reader done with message id #{msg_id}.")


      end # while

      IBLogger.debug("Reader done.")
    end # reader

  end # class IB
end # module IB
