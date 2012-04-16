module IB
  module Messages
    module Incoming

      # Called Error in Java code, but in fact this type of messages also
      # deliver system alerts and additional (non-error) info from TWS.
      ErrorMessage = Error = Alert = def_message([4, 2],
                                                 [:error_id, :int],
                                                 [:code, :int],
                                                 [:message, :string])
      class Alert
        # Is it an Error message?
        def error?
          code < 1000
        end

        # Is it a System message?
        def system?
          code > 1000 && code < 2000
        end

        # Is it a Warning message?
        def warning?
          code > 2000
        end

        def to_human
          "TWS #{ error? ? 'Error' : system? ? 'System' : 'Warning'} #{code}: #{message}"
        end
      end # class Alert

    end # module Incoming
  end # module Messages
end # module IB
