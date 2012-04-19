module IB
  module Models

    # Base IB data Model class, in future it will be developed into ActiveModel
    class Model

      # IB Models can be either database-backed, or not
      # require 'ib-ruby/db' # to make IB models database-backed
      def self.for subclass
        if DB
          case subclass
            when :execution, :bar, :order_state
              # Just a couple of AR models introduced for now...
              ActiveRecord::Base
            else
              Model
          end
        else
          Model
        end
      end

      # If a opts hash is given, keys are taken as attribute names, values as data.
      # The model instance fields are then set automatically from the opts Hash.
      def initialize(opts={})
        error "Argument must be a Hash", :args unless opts.is_a?(Hash)

        props = self.class::DEFAULT_PROPS.merge(opts)

        props.keys.each { |key| self.send("#{key}=", props[key]) }
      end

      # ActiveModel-style attribute accessors
      def [] key
        #instance_variable_get "@#{key}".to_sym
        attributes[key.to_sym]
      end

      def []= key, val
        #instance_variable_set "@#{key}".to_sym, val
        attributes[key.to_sym] = val
      end

    end # Model
  end # module Models
end # module IB
