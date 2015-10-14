#!/usr/bin/env ruby

require "packer/builders"
require "packer/provisioners"

module Packer
  class Template
    def initialize(template={}, options={})
      @variables = template["variables"]
      @builders = template["builders"].map { |builder| Packer::Builders.load(builder, options) }
      @provisioners = template["provisioners"].map { |provisioner| Packer::Provisioners.load(provisioner, options) }
    end
  end
end

# vim:set ft=ruby :
