require 'active_model'
#require 'active_model/validations'

module IB
  module Models

    # Module adds prop Macro and
    module ModelProperties

      DEFAULT_PROPS = {}

      def self.included base
        base.extend Macros

        # Extending lighweight (not DB-backed) Model class to mimic AR::Base
        unless base.ancestors.include? ActiveModel::Validations
          base.class_eval do
            include ActiveModel::Validations

            def save
              false
            end

            alias save! save

            def self.find *args
              []
            end

          end
        end
      end

      attr_reader :created_at

      def initialize opts={}
        @created_at = Time.now
        super self.class::DEFAULT_PROPS.merge(opts)
      end

      module Macros
        def prop *properties
          prop_hash = properties.last.is_a?(Hash) ? properties.pop : {}

          properties.each { |names| define_property names, '' }
          prop_hash.each { |names, type| define_property names, type }
        end

        def define_property names, body
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

        def define_property_methods name, body={}
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
                         else
                           proc { self[name] }
                       end
              define_method name, &getter

              setter = case # Define setter
                         when body[:set].respond_to?(:call)
                           body[:set]
                         when body[:set]
                           proc { |value| self[name] = value.send "to_#{body[:set]}" }
                         when CODES[name] # property is encoded
                           proc { |value| self[name] = CODES[name][value] || value }
                         else
                           proc { |value| self[name] = value }
                       end
              define_method "#{name}=", &setter

              # Define validator(s)
              [body[:validate]].flatten.compact.each do |validator|
                case validator
                  when Proc
                    validates_each name, &validator
                  when Hash
                    validates name, validator.dup
                end
              end

            else # setter given
              define_property_methods name, :set => body
          end
        end
      end # module Macros

    end # module ModelProperties
  end
end

