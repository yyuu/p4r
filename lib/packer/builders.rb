#!/usr/bin/env ruby

require "digest/sha2"
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
        @build_id = Digest::SHA256.hexdigest([Time.new.to_i, $$, self.object_id, rand(1<<16)].join(":"))
        @template = template
        @definition = definition
        @options = options
      end
      attr_reader :build_id

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

      def debug(s)
        @template.logger.debug("#{build_id.slice(0, 8)} : #{s}")
      end

      def info(s)
        @template.logger.info("#{build_id.slice(0, 8)} : #{s}")
      end

      def warn(s)
        @template.logger.warn("#{build_id.slice(0, 8)} : #{s}")
      end

      def error(s)
        @template.logger.error("#{build_id.slice(0, 8)} : #{s}")
      end

      def put(source, destination, options={})
        raise(NotImplementedError)
      end

      def run(cmdline, options={})
        raise(NotImplementedError)
      end
    end
  end
end

# vim:set ft=ruby :
