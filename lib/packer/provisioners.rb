#!/usr/bin/env ruby

module Packer
  module Provisioners # :nodoc:
    def self.load(template, definition, options={})
      type = definition['type']
      require "packer/provisioners/#{type}"
      klass_name = type.downcase.scan(/\w+/).map(&:capitalize).join
      klass = Packer::Provisioners.const_get(klass_name)
      klass.new(template, definition, options)
    end

    class NullProvisioner # :nodoc:
      def initialize(template, definition, options={})
        @template = template
        @definition = definition
        @options = options
      end

      def apply(_builder, _options={})
        logger.debug([:apply, object_id].inspect)
      end

      def logger
        @template.logger
      end
    end
  end
end

# vim:set ft=ruby :
