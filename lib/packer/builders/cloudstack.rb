#!/usr/bin/env ruby

require "packer/builders/ssh"

module Packer
  module Builders
    class Cloudstack < Ssh
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
        "cloudstack.example.com"
      end
    end
  end
end

# vim:set ft=ruby :
