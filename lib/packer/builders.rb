#!/usr/bin/env ruby

require 'digest/sha2'
require 'shellwords'

module Packer
  module Builders
    def self.load(template, definition, options={})
      type = definition['type']
      require "packer/builders/#{type}"
      klass_name = type.downcase.scan(/\w+/).map(&:capitalize).join
      klass = Packer::Builders.const_get(klass_name)
      klass.new(template, definition, options)
    end

    class NullBuilder
      def initialize(template, definition, options={})
        @build_id = Digest::SHA256.hexdigest([Time.new.to_i, $$, self.object_id, rand(1<<16)].join(':')).slice(0, 8)
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
        @template.logger.debug("#{build_id} : #{s}")
      end

      def info(s)
        @template.logger.info("#{build_id} : #{s}")
      end

      def warn(s)
        @template.logger.warn("#{build_id} : #{s}")
      end

      def error(s)
        @template.logger.error("#{build_id} : #{s}")
      end

      def put(_source, _destination, _options={})
        fail(NotImplementedError)
      end

      def run(_cmdline, _options={})
        fail(NotImplementedError)
      end

      private

      def do_with_retry(n=16)
        n.times do |i|
          begin
            yield
            return true
          rescue => error
            if Array === error.backtrace
              warn(([error.to_s] + error.backtrace.map { |s| "\t" + s }).join("\n"))
            else
              warn(error.to_s)
            end
            wait = 1 + i + (rand(1 << i) & 0xff)
            debug("Sleeping #{wait} seconds before retrying....")
            sleep(wait)
          end
        end
        error("Retry failed after #{n} times.")
        return false
      end
    end
  end
end

# vim:set ft=ruby :
