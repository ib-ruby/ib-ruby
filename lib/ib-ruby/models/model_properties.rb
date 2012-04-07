require 'active_model'
#require 'active_model/validations'

module IB
  module Models

    # Module adds prop Macro and
    module ModelProperties

      # Short codes for most common Model properties
      CODES = {
          :side => {'B' => :buy, 'S' => :sell, 'H' => :short},
      }.freeze

      # Most common property processors
      PROPS = {
          :side =>
              {:get => proc { | | CODES[:side][self[:side]] }, # :buy / :sell / :short
               :set => proc { |val| # BUY/SELL/SSHORT/BOT/SOLD
                 self[:side] = case val.to_s.upcase
                                 when /SHORT/
                                   'H'
                                 when /^B/
                                   'B'
                                 when /^S/
                                   'S'
                               end },
               :validate => {:format => {:with => /^buy|sell|short$/,
                                         :message => "should be buy/sell/short"}},
              }
      }.freeze

      def self.included base
        base.extend Macros

        # Extending lighweight (not DB-backed) class
        unless base.ancestors.include? ActiveModel::Validations
          base.send :include, ActiveModel::Validations

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
            when Proc # setter
              define_property_methods name, :set => body
            when Array # [setter, getter, validators]
              define_property_methods name,
                                      :get => body[0],
                                      :set => body[1],
                                      :validate => body[2]
            when Hash # recursion ends HERE!

              # Define getter
              define_method(name, &body[:get] || proc { self[name] })

              # Define setter
              define_method("#{name}=", &body[:set] || proc { |value| self[name] = value })

              # Define validator(s)
              [body[:validate]].flatten.compact.each do |validator|
                case validator
                  when Proc
                    validates_each name, &validator
                  when Hash
                    validates name, validator.dup
                end
              end

            else
              define_property_methods name, :set =>
                  proc { |value| self[name] = value.send "to_#{body}" }
          end
        end
      end # module Macros

    end # module ModelProperties
  end
end

