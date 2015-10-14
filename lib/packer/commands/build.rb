#!/usr/bin/env ruby

require "parallel"

module Packer
  module Commands
    class Build < NullCommand
      def run(args=[], options={})
        templates = args.map { |template_file| load_template_file(template_file, options) }
        parallelism = Parallel.processor_count
        status = Parallel.map(templates, in_processes: parallelism) { |template|
          begin
            template.build(options)
          rescue => error
            logger.error("#{$$}: #{error}")
            false
          end
        }
        if status.all?
          exit(0)
        else
          logger.error("non-zero exit status: #{status.inspect}")
          exit(1)
        end
      end
    end
  end
end

# vim:set ft=ruby :
