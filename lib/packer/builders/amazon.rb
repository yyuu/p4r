#!/usr/bin/env ruby

require "packer/builders/ssh"

module Packer
  module Builders
    class Amazon < Ssh
      def setup(options={})
        super
      end

      def teardown(options={})
        super
      end

      def build(options={})
        super
      end

      def hostname()
        "amazon.example.com"
      end

      def put(bytes, path, options={})
        super
      end

      def run(cmdline, options={})
        super
      end
    end
  end
end

# vim:set ft=ruby :
