require 'active_model'
require 'active_support/concern'
require 'active_support/hash_with_indifferent_access'

module IB
  module Models

    # Module adds prop Macro and
    module ModelProperties
      extend ActiveSupport::Concern

      def default_attributes
        {:created_at => Time.now,
         :updated_at => Time.now,
        }
      end

      ### Instance methods

      # Default presentation
      def to_human
        "<#{self.class.to_s.demodulize}: " + attributes.map do |attr, value|
          "#{attr}: #{value}" unless value.nil?
        end.compact.sort.join(' ') + ">"
      end

      # Comparison support
      def content_attributes
        HashWithIndifferentAccess[attributes.reject do |(attr, _)|
          attr.to_s =~ /(_count)$/ ||
              [:created_at, :updated_at, :type,
               :id, :order_id, :contract_id].include?(attr.to_sym)
        end]
      end

      # Update nil attributes from given Hash or model
      def update_missing attrs
        attrs = attrs.content_attributes unless attrs.kind_of?(Hash)

        attrs.each { |attr, val| send "#{attr}=", val if send(attr).blank? }
        self # for chaining
      end

      # Default Model comparison
      def == other
        content_attributes.inject(true) { |res, (attr, value)| res && other.send(attr) == value } &&
            other.content_attributes.inject(true) { |res, (attr, value)| res && send(attr) == value }
      end

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
              define_property_methods name, :set => body, :get => body
          end
        end

        # Extending AR-backed Model class with attribute defaults
        if defined?(ActiveRecord::Base) && ancestors.include?(ActiveRecord::Base)
          def initialize opts={}
            super default_attributes.merge(opts)
          end
        else
          # Timestamps
          prop :created_at, :updated_at
        end

      end # included
    end # module ModelProperties
  end # module Models
end
