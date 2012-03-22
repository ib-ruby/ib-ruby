require 'ib-ruby/models/model_properties'

module IB
  module Models

    # Base IB data Model class, in future it will be developed into ActiveModel
    class Model
      extend ModelProperties

      attr_reader :created_at

      DEFAULT_PROPS = {}

      # If a opts hash is given, keys are taken as attribute names, values as data.
      # The model instance fields are then set automatically from the opts Hash.
      def initialize(opts={})
        error "Argument must be a Hash", :args unless opts.is_a?(Hash)
        @created_at = Time.now

        props = self.class::DEFAULT_PROPS.merge(opts)
        props.keys.each { |key| self.send("#{key}=", props[key]) }
      end

      # ActiveModel-style attribute accessors
      def [] key
        instance_variable_get "@#{key}".to_sym
      end

      def []= key, val
        instance_variable_set "@#{key}".to_sym, val
      end

    end # Model
  end # module Models
end # module IB
