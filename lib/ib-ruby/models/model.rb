module IB
  module Models

    # Base IB data Model class, in future it will be developed into ActiveModel
    class Model
      attr_reader :created_at

      # If a opts hash is given, keys are taken as attribute names, values as data.
      # The model instance fields are then set automatically from the opts Hash.
      #
      def initialize(opts={})
        raise ArgumentError.new("Argument must be a Hash") unless opts.is_a?(Hash)
        @created_at = Time.now

        opts.keys.each { |key| self.send("#{key}=", opts[key]) }
      end

      # ActiveModel-style attribute accessors
      def [] key
        self.send key
      end

      def []= key, val
        self.send "#{key}=", val
      end

    end # Model
  end # module Models
end # module IB
