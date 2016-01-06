#!/usr/bin/env ruby

require 'fileutils'
require 'tmpdir'

module Packer
  module Builders
    class Ssh < NullBuilder
      def initialize(template, definition, options={})
        super
        @ssh_tmpdir = Dir.mktmpdir
      end

      def setup(options={})
        super
        create_ssh_keypair(@ssh_tmpdir)
      end

      def teardown(options={})
        super
      ensure
        do_with_retry { delete_ssh_keypair(@ssh_tmpdir) }
      end

      def hostname
        fail(NotImplementedError)
      end

      def put(source, destination, _options={})
        debug(Shellwords.shelljoin(['scp', '-i', @ssh_private_key, source, "#{hostname}:#{destination}"]))
      end

      def run(cmdline, _options={})
        debug(Shellwords.shelljoin(['ssh', '-i', @ssh_private_key, hostname, '--', cmdline]))
      end

      private

      def create_ssh_keypair(tmpdir)
        cmdline = Shellwords.shelljoin(['ssh-keygen', '-N', '', '-f', File.join(tmpdir, 'identity')])
        if system(cmdline)
          @ssh_private_key = File.join(tmpdir, 'identity')
          @ssh_public_key = File.join(tmpdir, 'identity.pub')
          debug("Generated temporary ssh keypair in #{tmpdir.dump}.")
        else
          fail("failed: #{cmdline}")
        end
      end

      def delete_ssh_keypair(tmpdir)
        debug('Deleting temporary ssh keypair....')
        return unless tmpdir
        FileUtils.rm_rf(tmpdir)
        debug("Deleted temporary ssh keypair in #{tmpdir.dump}.")
      end
    end
  end
end

# vim:set ft=ruby :
