#!/usr/bin/env ruby

require "packer/builders/amazon"

module Packer
  module Builders
    class AmazonEbs < Amazon
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
        "amazon-ebs.example.com"
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
