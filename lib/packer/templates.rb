#!/usr/bin/env ruby

require "packer/builders"
require "packer/provisioners"

module Packer
  class Template
    def initialize(builders, provisioners, options={})
      @builders = builders.map { |builder| Packer::Builders.load(builder, options) }
      @provisioners = provisioners.map { |provisioner| Packer::Provisioners.load(provisioner, options) }
    end
  end
end

# vim:set ft=ruby :
