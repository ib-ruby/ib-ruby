module IB::Models

# Base IB data Model class
  class Model
    attr_reader :created_at

    # If a hash is given, keys are taken as attribute names, values as data.
    # The attrs of the instance are set automatically from the attributeHash.
    #
    # If no hash is given, #init is called in the instance. #init
    # should set the datum up in a generic state.
    #
    def initialize(attributeHash={})
      raise ArgumentError.new("Argument must be a Hash") unless attributeHash.is_a?(Hash)
      @created_at = Time.now
      attributeHash.keys.each do |key|
        self.send((key.to_s + "=").to_sym, attributeHash[key])
      end
    end
  end # Model
end # IB::Models
