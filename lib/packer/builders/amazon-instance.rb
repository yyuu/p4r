#!/usr/bin/env ruby

require 'packer/builders/amazon'

module Packer
  module Builders
    class AmazonInstance < Amazon
      def hostname
        if @machine
          @machine.ssh_ip_address
        else
          'amazon-instance.example.com'
        end
      end
    end
  end
end

# vim:set ft=ruby :
