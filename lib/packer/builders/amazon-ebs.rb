#!/usr/bin/env ruby

require "packer/builders/amazon"

module Packer
  module Builders
    class AmazonEbs < Amazon
      def hostname()
        if @machine
          @machine.ssh_ip_address
        else
          "amazon-ebs.example.com"
        end
      end
    end
  end
end

# vim:set ft=ruby :
