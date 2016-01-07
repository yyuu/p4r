#!/usr/bin/env ruby

require 'parallel'

module Packer
  module Commands
    class Build < NullCommand # :nodoc:
      def run(args = [], options = {})
        templates = args.map { |template_file| load_template_file(template_file, options) }
        parallelism = Parallel.processor_count

        begin
          status = build_templates(templates, parallelism, options)
        ensure
          clean_templates(templates, parallelism, options)
        end

        if status.all?
          exit(0)
        else
          logger.error("non-zero exit status: #{status.inspect}")
          exit(1)
        end
      end

      private

      def build_templates(templates, parallelism = 1, options = {})
        Parallel.map(templates, in_threads: parallelism) do |template|
          begin
            template.setup(options)
            template.build(options)
            true
          rescue => error
            print_error(error)
            false
          end
        end
      rescue Interrupt => error
        STDERR.puts(error)
        templates.map { false }
      end

      def clean_templates(templates, parallelism = 1, options = {})
        Parallel.each(templates, in_threads: parallelism) do |template|
          begin
            template.teardown(options)
          rescue => error
            print_error(error)
          end
        end
      rescue Interrupt => error
        STDERR.puts(error)
      end

      def print_error(error)
        error_info = [error.to_s] + Array(error.backtrace).map { |s| "\t" + s }
        logger.warn("#{Process.pid} : " + error_info.join("\n"))
      end
    end
  end
end

# vim:set ft=ruby :
