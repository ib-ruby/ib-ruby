module IB
  module Models

    # Base IB data Model class, in future it will be developed into ActiveModel
    class Model
      extend ActiveModel::Naming
      extend ActiveModel::Callbacks
      include ActiveModel::Validations
      include ActiveModel::Serialization
      include ActiveModel::Serializers::Xml
      include ActiveModel::Serializers::JSON

      # IB Models can be either database-backed, or not
      # require 'ib-ruby/db' # to make IB models database-backed
      def self.for subclass
        if DB
          case subclass
          when :execution, :bar, :order, :order_state, :combo_leg
            # Just a couple of AR models introduced for now...
            ActiveRecord::Base
          else
            Model
          end
        else
          Model
        end
      end

      attr_accessor :created_at, :updated_at, :attributes

      # If a opts hash is given, keys are taken as attribute names, values as data.
      # The model instance fields are then set automatically from the opts Hash.
      def initialize opts={}
        run_callbacks :initialize do
          error "Argument must be a Hash", :args unless opts.is_a?(Hash)

          attrs = default_attributes.merge(opts)
          attrs.keys.each { |key| self.send("#{key}=", attrs[key]) }
        end
      end

      # ActiveModel API (for serialization)

      def attributes
        @attributes ||= {}
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
          # TODO: Need something like @models ||= []
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
