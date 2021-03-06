#!/usr/bin/env ruby

module Packer
  module Provisioners
    class File < NullProvisioner # :nodoc:
      def apply(builder, options = {})
        source = @definition['source']
        destination = @definition['destination']
        builder.upload(source, destination, options)
      end
    end
  end
end

# vim:set ft=ruby :
