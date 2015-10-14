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
        logger.debug([:setup, self.object_id].inspect)
      end

      def teardown(options={})
        logger.debug([:teardown, self.object_id].inspect)
      end

      def build(options={})
        logger.debug([:build, self.object_id].inspect)
      end

      def logger
        @template.logger
      end

      def put(bytes, path, options={})
        logger.debug("put: #{path.inspect} (#{bytes.length} bytes)")
      end

      def run(cmdline, options={})
        logger.debug("run: #{cmdline}")
      end
    end
  end
end

# vim:set ft=ruby :
