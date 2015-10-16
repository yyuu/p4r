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
        do_with_retry { delete_ssh_keypair(@ssh_tmpdir) }
      end

      def hostname()
        raise(NotImplementedError)
      end

      def put(source, destination, options={})
        debug(Shellwords.shelljoin(["scp", source, "#{hostname}:#{destination}"]))
      end

      def run(cmdline, options={})
        debug(Shellwords.shelljoin(["ssh", hostname, "--", cmdline]))
      end

      private
      def create_ssh_keypair(tmpdir)
        cmdline = Shellwords.shelljoin(["ssh-keygen", "-N", "", "-f", File.join(tmpdir, "identity")])
        if system(cmdline)
          @ssh_private_key = File.join(tmpdir, "identity")
          @ssh_public_key = File.join(tmpdir, "identity.pub")
          debug("Generated temporary ssh keypair in #{tmpdir.dump}.")
        else
          raise("failed: #{cmdline}")
        end
      end

      def delete_ssh_keypair(tmpdir)
        debug("Deleting temporary ssh keypair....")
        if tmpdir
          FileUtils.rm_rf(tmpdir)
          debug("Deleted temporary ssh keypair in #{tmpdir.dump}.")
        end
      end
    end
  end
end

# vim:set ft=ruby :
