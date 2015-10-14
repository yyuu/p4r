#!/usr/bin/env ruby

module Packer
  module Builders
    def self.load(definition, options={})
      type = definition["type"]
      require "packer/builders/#{type}"
      klass_name = type.downcase.split("-").map { |s| s.capitalize }.join
      klass = Packer::Builders.const_get(klass_name)
      klass.new(definition, options)
    end

    class NullBuilder
      def initialize(definition, options={})
        @definition = definition
        @options = options
      end
    end
  end
end

# vim:set ft=ruby :
