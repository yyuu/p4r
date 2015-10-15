#!/usr/bin/env ruby

require "digest/sha2"
require "packer/builders/ssh"

module Packer
  module Builders
    class Amazon < Ssh
      def setup(options={})
        super
        @amazon_security_group = "packer-#{Digest::SHA256.hexdigest(Time.new.to_s).slice(0, 16)}"
        create_security_group(@amazon_security_group)
      end

      def teardown(options={})
        super
      ensure
        begin
          delete_security_group(@amazon_security_group)
        rescue => error
          logger.warn(error)
        end
      end

      def build(options={})
        super
      end

      def hostname()
        "amazon.example.com"
      end

      def put(bytes, path, options={})
        super
      end

      def run(cmdline, options={})
        super
      end

      private
      def authorize_ssh_public_key(ssh_public_key)
        super
        logger.debug("register ssh public key at #{ssh_public_key.dump} to amazon")
      end

      def revoke_ssh_public_key(ssh_public_key)
        super
      ensure
        logger.debug("revoke ssh public key at #{ssh_public_key.dump} from amazon")
      end

      def create_security_group(security_group)
        logger.debug("create security group #{security_group.dump}")
      end

      def delete_security_group(security_group)
        logger.debug("delete security group #{security_group.dump}")
      end
    end
  end
end

# vim:set ft=ruby :
