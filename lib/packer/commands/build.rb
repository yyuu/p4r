#!/usr/bin/env ruby

module Packer
  module Commands
    class Build < BaseCommand
      def run(args=[], options={})
        args.each do |template_file|
          template = load_template_file(template_file, options)
          p(template)
        end
      end
    end
  end
end

# vim:set ft=ruby :
