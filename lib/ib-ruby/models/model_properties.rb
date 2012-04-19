require 'active_model'
require 'active_support/concern'

module IB
  module Models

    # Module adds prop Macro and
    module ModelProperties
      extend ActiveSupport::Concern

      DEFAULT_PROPS = {}

      ### Instance methods

      included do

        ### Class macros

        def self.prop *properties
          prop_hash = properties.last.is_a?(Hash) ? properties.pop : {}

          properties.each { |names| define_property names, nil }
          prop_hash.each { |names, type| define_property names, type }
        end

        def self.define_property names, body
          aliases = [names].flatten
          name = aliases.shift
          instance_eval do

            define_property_methods name, body

            aliases.each do |ali|
              alias_method "#{ali}", name
              alias_method "#{ali}=", "#{name}="
            end
          end
        end

        def self.define_property_methods name, body={}
          #p name, body
          case body
            when '' # default getter and setter
              define_property_methods name

            when Array # [setter, getter, validators]
              define_property_methods name,
                                      :get => body[0],
                                      :set => body[1],
                                      :validate => body[2]

            when Hash # recursion base case
              getter = case # Define getter
                         when body[:get].respond_to?(:call)
                           body[:get]
                         when body[:get]
                           proc { self[name].send "to_#{body[:get]}" }
                         when VALUES[name] # property is encoded
                           proc { VALUES[name][self[name]] }
                            #when respond_to?(:column_names) && column_names.include?(name.to_s)
                            #  # noop, ActiveRecord will take care of it...
                            #  p "#{name} => get noop"
                            #  p respond_to?(:column_names) && column_names
                         else
                           proc { self[name] }
                       end
              define_method name, &getter if getter

              setter = case # Define setter
                         when body[:set].respond_to?(:call)
                           body[:set]
                         when body[:set]
                           proc { |value| self[name] = value.send "to_#{body[:set]}" }
                         when CODES[name] # property is encoded
                           proc { |value| self[name] = CODES[name][value] || value }
                         else
                           proc { |value| self[name] = value } # p name, value;
                       end
              define_method "#{name}=", &setter if setter

              # Define validator(s)
              [body[:validate]].flatten.compact.each do |validator|
                case validator
                  when Proc
                    validates_each name, &validator
                  when Hash
                    validates name, validator.dup
                end
              end

            # TODO define self[:name] accessors for :virtual and :flag properties

            else # setter given
              define_property_methods name, :set => body
          end
        end

        # Extending lighweight (not DB-backed) Model class to mimic AR::Base
        if ancestors.include? ActiveModel::Validations

          def initialize opts={}
            super self.class::DEFAULT_PROPS.merge(opts)
          end

        else
          extend ActiveModel::Naming
          extend ActiveModel::Callbacks
          include ActiveModel::Validations
          include ActiveModel::Serialization
          include ActiveModel::Serializers::Xml
          include ActiveModel::Serializers::JSON

          attr_accessor :created_at, :updated_at, :attributes

          def initialize opts={}
            run_callbacks :initialize do
              self.created_at = Time.now
              self.updated_at = Time.now
              super self.class::DEFAULT_PROPS.merge(opts)
            end
          end

          # ActiveModel API (for serialization)

          def attributes
            @attributes ||= {}
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

        end

      end # included
    end # module ModelProperties
  end # module Models
end
