#!/usr/bin/env ruby

require "shellwords"

module Packer
  module Builders
    def self.load(template, definition, options={})
      type = definition["type"]
      require "packer/builders/#{type}"
      klass_name = type.downcase.scan(/\w+/).map { |s| s.capitalize }.join
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
        # nop
      end

      def teardown(options={})
        # nop
      end

      def build(options={})
        # nop
      end

      def logger
        @template.logger
      end

      def put(bytes, path, options={})
        raise(NotImplementedError)
      end

      def run(cmdline, options={})
        raise(NotImplementedError)
      end
    end
  end
end

# vim:set ft=ruby :
