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
        authorize_ssh_public_key(@ssh_public_key)
      end

      def teardown(options={})
        super
      ensure
        begin
          revoke_ssh_public_key(@ssh_public_key)
        rescue => error
          logger.warn(error)
        end
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
          logger.debug("generated temporary ssh keypair at #{tmpdir.dump}")
        else
          raise("failed: #{cmdline}")
        end
      end

      def delete_ssh_keypair(tmpdir)
        FileUtils.rm_rf(tmpdir)
        logger.debug("removed temporary ssh keypair at #{tmpdir.dump}")
      end

      def authorize_ssh_public_key(ssh_public_key)
        logger.debug("authorize ssh public key at #{ssh_public_key.dump}")
      end

      def revoke_ssh_public_key(ssh_public_key)
        logger.debug("revoke ssh public key at #{ssh_public_key.dump}")
      end
    end
  end
end

# vim:set ft=ruby :
