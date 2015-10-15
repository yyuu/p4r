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

    class SshBuilder < NullBuilder
      def hostname()
        "127.0.0.1"
      end

      def put(bytes, path, options={})
        logger.debug(Shellwords.shelljoin(["scp", "-", "#{hostname}:#{path}"]))
      end

      def run(cmdline, options={})
        logger.debug(Shellwords.shelljoin(["ssh", hostname, "--", cmdline]))
      end
    end
  end
end

# vim:set ft=ruby :
