module IB::Models

# Base IB data Model class
  class Model
    attr_reader :created_at

    def init_empty
      @created_at = Time.now
    end

    # If a hash is given, keys are taken as attribute names, values as data.
    # The attrs of the instance are set automatically from the attributeHash.
    #
    # If no hash is given, #init is called in the instance. #init
    # should set the datum up in a generic state.
    #
    def initialize(attributeHash=nil)
      if attributeHash.nil?
        init_empty # TODO: Ugly, get rid of it
      else
        raise ArgumentError.new("Argument must be a Hash") unless attributeHash.is_a?(Hash)
        attributeHash.keys.each { |key|
          self.send((key.to_s + "=").to_sym, attributeHash[key])
        }
      end
    end
  end # Model
end # IB::Models
