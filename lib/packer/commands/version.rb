#!/usr/bin/env ruby

require 'rbconfig'

module Packer
  module Commands
    class Version < NullCommand
      def run(_args=[], _options={})
        ruby = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
        exit(system(ruby, $PROGRAM_NAME, '--version') ? 0 : 1)
      end
    end
  end
end

# vim:set ft=ruby :
