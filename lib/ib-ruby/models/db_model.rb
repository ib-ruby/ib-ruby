require 'ib-ruby/models/model_properties'

module IB
  module Models

    # Base IB Model class derived from ActiveRecord
    class DBModel < ActiveRecord::Base
      extend ModelProperties

      attr_reader :created_at

      DEFAULT_PROPS = {}

      # If a opts hash is given, keys are taken as attribute names, values as data.
      # The model instance fields are then set automatically from the opts Hash.
      def initialize(opts={})

        check_that_match_all props, columns

        error "Argument must be a Hash", :args unless opts.is_a?(Hash)
        @created_at = Time.now

        props = self.class::DEFAULT_PROPS.merge(opts)
        props.keys.each { |key| self.send("#{key}=", props[key]) }
      end

    end # Model
  end # module Models
end # module IB
