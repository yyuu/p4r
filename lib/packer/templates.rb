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

    def build(options={})
      parallelism = Parallel.processor_count
      begin
        Parallel.map(@builders, in_threads: parallelism) do |builder|
          builder.setup(options.dup)
        end
        machines = Parallel.map(@builders, in_threads: parallelism) { |builder|
          builder.build(options.dup)
        }
        Parallel.each(machines, in_threads: parallelism) do |machine|
          @provisioners.each do |provisioner|
            provisioner.apply(machine, options.dup)
          end
        end
      ensure
        Parallel.each(@builders, in_threads: parallelism) do |builder|
          builder.teardown(options.dup) rescue nil
        end
      end
    end

    def logger
      @command.logger
    end
  end
end

# vim:set ft=ruby :
