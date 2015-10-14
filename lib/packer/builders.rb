#!/usr/bin/env ruby

module Packer
  module Builders
    def self.load(template, definition, options={})
      type = definition["type"]
      require "packer/builders/#{type}"
      klass_name = type.downcase.split("-").map { |s| s.capitalize }.join
      klass = Packer::Builders.const_get(klass_name)
      klass.new(template, definition, options)
    end

    class NullBuilder
      def initialize(template, definition, options={})
        @template = template
        @definition = definition
        @options = options
      end

      def setup(options={})
        logger.debug([:setup, self].inspect)
      end

      def teardown(options={})
        logger.debug([:teardown, self].inspect)
      end

      def build(options={})
        logger.debug([:build, self].inspect)
      end

      def logger
        @template.logger
      end
    end
  end
end

# vim:set ft=ruby :
