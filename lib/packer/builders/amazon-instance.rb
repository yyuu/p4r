#!/usr/bin/env ruby

require 'packer/builders/amazon'

module Packer
  module Builders
    class AmazonInstance < Amazon
      def hostname
        if options[:dry_run]
          'amazon-instance'
        else
          if @machine
            @machine.ssh_ip_address
          else
            raise('invalid state')
          end
        end
      end
    end
  end
end

# vim:set ft=ruby :
