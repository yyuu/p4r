#!/usr/bin/env ruby

require 'parallel'

module Packer
  module Commands
    class Build < NullCommand # :nodoc:
      def run(args=[], options={})
        templates = args.map { |template_file| load_template_file(template_file, options) }
        parallelism = Parallel.processor_count

        begin
          status = Parallel.map(templates, in_threads: parallelism) do |template|
            begin
              template.setup(options)
              template.build(options)
              true
            rescue => error
              if error.backtrace.is_a?(Array)
                logger.error("#{Process.pid} : " + ([error.to_s] + error.backtrace.map { |s| "\t" + s }).join("\n"))
              else
                logger.error("#{Process.pid} : " + error.to_s)
              end
              false
            end
          end
        rescue Interrupt
          status = templates.map { false }
        end

        begin
          Parallel.each(templates, in_threads: parallelism) do |template|
            begin
              template.teardown(options)
            rescue => error
              if error.backtrace.is_a?(Array)
                logger.warn("#{Process.pid} : " + ([error.to_s] + error.backtrace.map { |s| "\t" + s }).join("\n"))
              else
                logger.warn("#{Process.pid} : " + error.to_s)
              end
            end
          end
        rescue Interrupt => error
          STDERR.puts(error)
        end

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
