#!/usr/bin/env ruby

require 'rbconfig'

module Packer
  module Commands
    class Help < NullCommand
      def run(_args=[], _options={})
        ruby = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
        exit(system(ruby, $0, '--help') ? 0 : 1)
      end
    end
  end
end

# vim:set ft=ruby :
