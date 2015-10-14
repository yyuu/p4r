#!/usr/bin/env ruby

require "fileutils"
require "multi_json"
require "oj"
require "packer/templates"

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

      private
      def load_template_file(template_file, options={})
        load_template_string(File.read(template_file), options)
      end

      def load_template_string(template_string, options={})
        load_template(MultiJson.load(template_string), options)
      end

      def load_template(template, options={})
        Packer::Template.new(template, options)
      end
    end
  end
end

# vim:set ft=ruby :
