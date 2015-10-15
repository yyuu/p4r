#!/usr/bin/env ruby

module Packer
  module Builders
    class Ssh < NullBuilder
      def hostname()
        "127.0.0.1"
      end

      def put(bytes, path, options={})
        logger.debug(Shellwords.shelljoin(["scp", "-", "#{hostname}:#{path}"]))
      end

      def run(cmdline, options={})
        logger.debug(Shellwords.shelljoin(["ssh", hostname, "--", cmdline]))
      end
    end
  end
end

# vim:set ft=ruby :
