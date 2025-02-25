# frozen_string_literal: true

require "set"

require "dry/configurable/constants"
require "dry/configurable/dsl"
require "dry/configurable/methods"
require "dry/configurable/settings"

module Dry
  module Configurable
    module ClassMethods
      include Methods

      # @api private
      def inherited(klass)
        super

        parent_settings = (respond_to?(:config) ? config._settings : _settings)

        klass.instance_variable_set("@_settings", parent_settings)
      end

      # Add a setting to the configuration
      #
      # @param [Mixed] name
      #   The accessor key for the configuration value
      # @param [Mixed] default
      #   Default value for the setting
      # @param [#call] constructor
      #   Transformation given value will go through
      # @param [Boolean] reader
      #   Whether a reader accessor must be created
      # @yield
      #   A block can be given to add nested settings.
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def setting(*args, **options, &block)
        setting = __config_dsl__.setting(*args, **options, &block)

        _settings << setting

        __config_reader__.define(setting.name) if setting.reader?

        self
      end

      # Return declared settings
      #
      # @return [Set<Symbol>]
      #
      # @api public
      def settings
        @settings ||= Set[*_settings.map(&:name)]
      end

      # Return declared settings
      #
      # @return [Settings]
      #
      # @api public
      def _settings
        @_settings ||= Settings.new
      end

      # Return configuration
      #
      # @return [Config]
      #
      # @api public
      def config
        @config ||= Config.new(_settings)
      end

      # @api private
      def __config_dsl__
        @dsl ||= DSL.new
      end

      # @api private
      def __config_reader__
        @__config_reader__ ||=
          begin
            reader = Module.new do
              def self.define(name)
                define_method(name) do
                  config[name]
                end
              end
            end

            if included_modules.include?(InstanceMethods)
              include(reader)
            end

            extend(reader)

            reader
          end
      end
    end
  end
end
