#!/usr/bin/env ruby

module Packer
  module Provisioners
    def self.load(template, definition, options={})
      type = definition["type"]
      require "packer/provisioners/#{type}"
      klass_name = type.downcase.split("-").map { |s| s.capitalize }.join
      klass = Packer::Provisioners.const_get(klass_name)
      klass.new(template, definition, options)
    end

    class NullProvisioner
      def initialize(template, definition, options={})
        @template = template
        @definition = definition
        @options = options
      end

      def apply(builder, options={})
        logger.debug([:apply, self].inspect)
      end

      def logger
        @template.logger
      end
    end
  end
end

# vim:set ft=ruby :
