#!/usr/bin/env ruby

require "logger"
require "optparse"
require "packer/commands"
require "packer/version"

module Packer
  class Application
    def initialize()
      @optparse = OptionParser.new
      @optparse.version = Packer::VERSION
      @options = {
        debug: false,
        logger: Logger.new(STDERR).tap { |logger|
          logger.level = Logger::INFO
        },
      }
      define_options
    end
    attr_reader :options
    attr_reader :optparse

    def main(argv=[])
      args = @optparse.order(argv)
      begin
        command = ( args.shift || "help" )
        get_command(command).tap do |cmd|
          @optparse.banner = "Usage: packer #{command} [options]"
          cmd.define_options(@optparse, @options)
          args = cmd.parse_options(@optparse, args)
          if options[:debug]
            options[:logger].level = Logger::DEBUG
          end
          cmd.run(args, @options)
        end
      rescue OptionParser::ParseError => error
        STDERR.puts("packer: #{error.message}")
        get_command("help").tap do |cmd|
          cmd.run([], @options)
        end
        exit(1)
      rescue Errno::EPIPE
        exit(0)
      end
    end

    private
    def define_options
      @optparse.on("-d", "--[no-]debug", "Enable debug mode") do |v|
        options[:debug] = v
      end
    end

    def const_name(name)
      name.to_s.split(/[^\w]+/).map { |s| s.capitalize }.join
    end

    def get_command(name)
      klass_name = const_name(name)
      begin
        klass = Packer::Commands.const_get(klass_name)
      rescue NameError
        require "packer/commands/#{name}"
        begin
          klass = Packer::Commands.const_get(klass_name)
        rescue NameError
          raise
        end
      end
      klass.new(self)
    end
  end
end

# vim:set ft=ruby :
