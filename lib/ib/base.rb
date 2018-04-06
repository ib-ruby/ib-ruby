module IB

  # Base class for tableless IB data Models, extends ActiveModel API
  class Base
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Validations
    include ActiveModel::Serialization
    #include ActiveModel::Serializers::Xml
    include ActiveModel::Serializers::JSON

    define_model_callbacks :initialize

    # If a opts hash is given, keys are taken as attribute names, values as data.
    # The model instance fields are then set automatically from the opts Hash.
    def initialize attributes={}, opts={}
      run_callbacks :initialize do
        error "Argument must be a Hash", :args unless attributes.is_a?(Hash)

        self.attributes = attributes # set_attribute_defaults is now after_init callback
      end
    end

    # ActiveModel API (for serialization)

    def attributes
      @attributes ||= Hash.new #HashWithIndifferentAccess.new
    end

    def attributes= attrs
      attrs.keys.each { |key| self.send("#{key}=", attrs[key]) }
    end

    # ActiveModel-style read/write_attribute accessors
    def [] key
      attributes[key.to_sym]
    end

    def update_attribute key, value
      @attributes[key.to_sym] = value
    end

    def []= key, val
      # p key, val
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

    ### Noop methods mocking ActiveRecord::Base macros
    
    def self.attr_protected *args
    end

    def self.attr_accessible *args
    end

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
end # module IB
