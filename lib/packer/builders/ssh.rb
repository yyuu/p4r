#!/usr/bin/env ruby

require "fileutils"
require "tmpdir"

module Packer
  module Builders
    class Ssh < NullBuilder
      def setup(options={})
        super
        @ssh_tmpdir = Dir.mktmpdir
        create_ssh_keypair(@ssh_tmpdir)
      end

      def teardown(options={})
        super
      ensure
        begin
          delete_ssh_keypair(@ssh_tmpdir)
        rescue => error
          logger.warn(error)
        end
      end

      def hostname()
        "127.0.0.1"
      end

      def put(bytes, path, options={})
        logger.debug(Shellwords.shelljoin(["scp", "-", "#{hostname}:#{path}"]))
      end

      def run(cmdline, options={})
        logger.debug(Shellwords.shelljoin(["ssh", hostname, "--", cmdline]))
      end

      private
      def create_ssh_keypair(tmpdir)
        cmdline = Shellwords.shelljoin(["ssh-keygen", "-N", "", "-f", File.join(tmpdir, "identity")])
        if system(cmdline)
          @ssh_private_key = File.join(tmpdir, "identity")
          @ssh_public_key = File.join(tmpdir, "identity.pub")
          logger.debug("Generated temporary ssh keypair as #{@ssh_private_key.dump} and #{@ssh_public_key.dump}.")
        else
          raise("failed: #{cmdline}")
        end
      end

      def delete_ssh_keypair(tmpdir)
        FileUtils.rm_rf(tmpdir)
        logger.debug("Removed temporary ssh keypair of #{@ssh_private_key.dump} and #{@ssh_public_key.dump}.")
      end
    end
  end
end

# vim:set ft=ruby :
