#!/usr/bin/env ruby

require 'fileutils'
require 'shellwords'
require 'tmpdir'

module Packer
  module Builders
    class Ssh < NullBuilder # :nodoc:
      def initialize(template, definition, options = {})
        super
        @ssh_tmpdir = Dir.mktmpdir
      end

      def setup(options = {})
        super
        create_ssh_keypair(@ssh_tmpdir)
      end

      def teardown(options = {})
        super
      ensure
        do_with_retry do
          delete_ssh_keypair(@ssh_tmpdir)
        end
      end

      def build(options = {})
        # nop
      end

      def ssh_hostname
        fail(NotImplementedError)
      end

      def ssh_username
        fail(NotImplementedError)
      end

      def upload(source, destination, _options = {})
        args = ['scp']
        args << '-F' << '/dev/null'
        args << '-i' << @ssh_private_key
        args << '-o' << 'ConnectTimeout=60'
        args << '-o' << 'StrictHostKeyChecking=no'
        args << '-o' << 'UserKnownHostsFile=/dev/null'
        args << '-o' << "User=#{ssh_username}"
        args << source << "#{ssh_hostname}:#{destination}"
        scp = Shellwords.shelljoin(args)
        debug(scp)
        if system(scp)
          true
        else
          fail("failed: #{scp}")
        end
      end

      def run(cmdline, _options = {})
        args = ['ssh']
        args << '-F' << '/dev/null'
        args << '-i' << @ssh_private_key
        args << '-o' << 'ConnectTimeout=60'
        args << '-o' << 'StrictHostKeyChecking=no'
        args << '-o' << 'UserKnownHostsFile=/dev/null'
        args << '-o' << "User=#{ssh_username}"
        args << ssh_hostname
        args << "--" << cmdline
        ssh = Shellwords.shelljoin(args)
        debug(ssh)
        if system(ssh)
          true
        else
          fail("failed: #{ssh}")
        end
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
