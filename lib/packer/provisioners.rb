#!/usr/bin/env ruby

module Packer
  module Provisioners
    def self.load(definition, options={})
      type = definition["type"]
      require "packer/provisioners/#{type}"
      klass_name = type.downcase.split("-").map { |s| s.capitalize }.join
      klass = Packer::Provisioners.const_get(klass_name)
      klass.new(definition, options)
    end

    class NullProvisioner
      def initialize(definition, options={})
        @definition = definition
        @options = options
      end
    end
  end
end

# vim:set ft=ruby :
