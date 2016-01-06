#!/usr/bin/env ruby

require 'fileutils'
require 'multi_json'
require 'oj'
require 'packer/templates'

module Packer
  module Commands
    class NullCommand
      def initialize(application, _options={})
        @application = application
      end
      attr_reader :application

      def run(_args=[], _options={})
        fail(NotImplementedError)
      end

      def define_options(_optparse, _options={})
        # nop
      end

      def parse_options(optparse, args=[])
        optparse.parse(args)
      end

      def logger
        @application.logger
      end

      private

      def load_template_file(template_file, options={})
        load_template_string(File.read(template_file), options)
      end

      def load_template_string(template_string, options={})
        load_template(MultiJson.load(template_string), options)
      end

      def load_template(template, options={})
        runtime_variables = options.fetch(:variables, {})
        variables = Hash[template.fetch('variables', {}).merge(runtime_variables).map do |k, v|
          [k, prepare_string('env', v, ENV)]
        end]
        builders = prepare(template.fetch('builders', []), variables)
        provisioners = prepare(template.fetch('provisioners', []), variables)
        Packer::Template.new(self, builders, provisioners, options)
      end

      def prepare(x, variables={})
        case x
        when Array
          x.map { |e| prepare(e, variables) }
        when Hash
          Hash[x.map { |k, v| [prepare(k, variables), prepare(v, variables)] }]
        when String
          prepare_string('user', x, variables)
        else
          x
        end
      end

      def prepare_string(prefix, s, variables={})
        s.gsub(/{{\s*#{Regexp.escape(prefix)}\s+`([^}]*)`\s*}}/) do
          name = Regexp.last_match[1].strip
          if variables.key?(name)
            variables[name].to_s
          else
            fail("#{prefix} not found: #{name.inspect}: #{variables.inspect}")
          end
        end
      end
    end
  end
end

# vim:set ft=ruby :
