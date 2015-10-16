#!/usr/bin/env ruby

require "parallel"
require "packer/builders"
require "packer/provisioners"

module Packer
  class Template
    def initialize(command, builders, provisioners, options={})
      @command = command
      @builders = builders.map { |builder| Packer::Builders.load(self, builder, options) }
      @provisioners = provisioners.map { |provisioner| Packer::Provisioners.load(self, provisioner, options) }
    end

    def setup(options={})
      parallelism = Parallel.processor_count
      Parallel.each(@builders, in_threads: parallelism) do |builder|
        builder.setup(options.dup)
      end
    end

    def build(options={})
      parallelism = Parallel.processor_count
      Parallel.each(@builders, in_threads: parallelism) do |builder|
        builder.build(options.dup)
      end
      Parallel.each(@builders, in_threads: parallelism) do |builder|
        @provisioners.each do |provisioner|
          provisioner.apply(builder, options.dup)
        end
      end
    end

    def teardown(options={})
      parallelism = Parallel.processor_count
      Parallel.each(@builders, in_threads: parallelism) do |builder|
        builder.teardown(options.dup)
      end
    end

    def logger
      @command.logger
    end
  end
end

# vim:set ft=ruby :
