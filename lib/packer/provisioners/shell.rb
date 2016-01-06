#!/usr/bin/env ruby

module Packer
  module Provisioners
    class Shell < NullProvisioner # :nodoc:
      def apply(builder, options = {})
        inline = @definition['inline'].join("\n")
        builder.run(inline, options)
      end
    end
  end
end

# vim:set ft=ruby :
