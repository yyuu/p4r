#!/usr/bin/env ruby

module Packer
  module Provisioners
    class File < NullProvisioner
      def apply(builder, options={})
        source = @definition["source"]
        destination = @definition["destination"]
        builder.put(source, destination, options)
      end
    end
  end
end

# vim:set ft=ruby :
