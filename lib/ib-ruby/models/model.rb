module IB
  module Models

    # Base class for tableless IB data Models extends ActiveModel API
    class Model
      extend ActiveModel::Naming
      extend ActiveModel::Callbacks
      include ActiveModel::Validations
      include ActiveModel::Serialization
      include ActiveModel::Serializers::Xml
      include ActiveModel::Serializers::JSON

      # IB Models can be either database-backed, or not
      # require 'ib-ruby/db' # to make all IB models database-backed
      # If you plan to persist only specific Models, select those subclasses here:
      def self.for subclass
        if DB # && [:contract, :order, :order_state].include? subclass
          ActiveRecord::Base
        else
          Model
        end
      end

      #attr_accessor :attributes

      # If a opts hash is given, keys are taken as attribute names, values as data.
      # The model instance fields are then set automatically from the opts Hash.
      def initialize attributes={}, opts={}
        run_callbacks :initialize do
          error "Argument must be a Hash", :args unless attributes.is_a?(Hash)

          self.attributes = default_attributes.merge(attributes)
        end
      end

      # ActiveModel API (for serialization)

      def attributes
        @attributes ||= HashWithIndifferentAccess.new
      end

      def attributes= attrs
        attrs.keys.each { |key| self.send("#{key}=", attrs[key]) }
      end

      # ActiveModel-style read/write_attribute accessors
      def [] key
        attributes[key.to_sym]
      end

      def []= key, val
        attributes[key.to_sym] = val
      end

      def to_model
        self
      end

      def new_record?
        true
      end

      def save
        valid?
      end

      alias save! save

      ### ActiveRecord::Base association API mocks

      def self.belongs_to model, *args
        attr_accessor model
      end

      def self.has_one model, *args
        attr_accessor model
      end

      def self.has_many models, *args
        attr_accessor models

        define_method(models) do
          self.instance_variable_get("@#{models}") ||
              self.instance_variable_set("@#{models}", [])
        end
      end

      def self.find *args
        []
      end

      ### ActiveRecord::Base callback API mocks

      define_model_callbacks :initialize, :only => :after

      ### ActiveRecord::Base misc

      def self.serialize *properties
      end


    end # Model
  end # module Models
end # module IB
