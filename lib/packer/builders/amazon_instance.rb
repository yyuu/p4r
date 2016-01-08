#!/usr/bin/env ruby

require 'packer/builders/amazon'

module Packer
  module Builders
    class AmazonInstance < Amazon # :nodoc:
      def hostname
        if @machine
          @machine.ssh_ip_address
        else
          fail('invalid state')
        end
      end
    end
  end
end

# vim:set ft=ruby :
