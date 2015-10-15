#!/usr/bin/env ruby

require "logger"
require "optparse"
require "packer/commands"
require "packer/version"

module Packer
  class Application
    def initialize()
      @logger = Logger.new(STDERR).tap do |logger|
#       logger.level = Logger::INFO
        logger.level = Logger::DEBUG
      end
      @optparse = OptionParser.new
      @optparse.version = Packer::VERSION
      @options = {
        dry_run: false,
        debug: false,
        variables: {},
      }
      define_options
    end
    attr_reader :logger

    def main(argv=[])
      args = @optparse.order(argv)
      begin
        command = ( args.shift || "help" )
        get_command(command).tap do |cmd|
          @optparse.banner = "Usage: packer #{command} [options]"
          cmd.define_options(@optparse, @options)
          args = cmd.parse_options(@optparse, args)
          if @options[:debug]
            @logger.level = Logger::DEBUG
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
    def define_options()
      @optparse.on("-d", "--[no-]debug", "Enable debug mode") do |v|
        @options[:debug] = v
      end
      @optparse.on("--[no-]dry-run", "Enable dry run") do |v|
        @options[:dry_run] = v
      end
      @optparse.on("--var KEY_VALUE", "Variable for template") do |v|
        key, val = v.split(/\s*=\s*/, 2)
        @options[:variables][key.strip] = (val || "").strip
      end
      @optparse.on("--var-file PATH", "JSON file containing user variables") do |v|
        @options[:variables] = @options[:variables].merge(MultiJson.load(File.read(v)))
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
        begin
          require "packer/commands/#{name}"
        rescue LoadError
          raise(OptionParser::ParseError.new("unknown command: #{name}"))
        end
        begin
          klass = Packer::Commands.const_get(klass_name)
        rescue NameError
          require "packer/commands/help"
          klass = Packer::Commands::Help
        end
      end
      klass.new(self)
    end
  end
end

# vim:set ft=ruby :
