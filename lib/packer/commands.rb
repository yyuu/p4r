#!/usr/bin/env ruby

require "fileutils"
require "multi_json"
require "oj"

module Packer
  module Commands
    class BaseCommand
      def initialize(application)
        @application = application
        @logger = application.options[:logger]
        @options = application.options
      end
      attr_reader :application
      attr_reader :logger
      attr_reader :options

      def run(args=[], options={})
        raise(NotImplementedError)
      end

      def define_options(optparse, options={})
        # nop
      end

      def parse_options(optparse, args=[])
        optparse.parse(args)
      end
    end
  end
end

# vim:set ft=ruby :
