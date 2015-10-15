#!/usr/bin/env ruby

require "digest/sha2"
require "fog"
require "packer/builders/ssh"

module Packer
  module Builders
    class Amazon < Ssh
      def setup(options={})
        super
        @fog_compute = Fog::Compute.new(
          provider: "AWS",
          aws_access_key_id: @definition["access_key"],
          aws_secret_access_key: @definition["secret_key"],
          region: @definition["region"],
        )
        @amazon_key_pair = "packer-#{@build_id.slice(0, 16)}"
        @amazon_security_group = "packer-#{@build_id.slice(0, 16)}"
        create_key_pair(@amazon_key_pair, @ssh_public_key)
        create_security_group(@amazon_security_group)
      end

      def teardown(options={})
        super
      ensure
        begin
          delete_key_pair(@amazon_key_pair, @ssh_public_key)
        rescue => error
          logger.warn(error)
        end
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
      def create_key_pair(name, public_key)
        if @fog_compute.key_pairs.get(name).nil?
          key_pair = @fog_compute.key_pairs.new(name: name)
          key_pair.public_key = File.read(public_key)
          logger.debug("Created temporary key pair #{name.dump} from #{public_key.dump}.")
        else
          raise("key pair already exists: #{name.dump}")
        end
      end

      def delete_key_pair(name, public_key)
        if key_pair = @fog_compute.key_pairs.get(name)
          key_pair.destroy
          logger.debug("Deleted temporary key pair #{name.dump}.")
        end
      end

      def create_security_group(name)
        if @fog_compute.security_groups.get(name).nil?
          security_group = @fog_compute.security_groups.create(name: name, description: name)
          security_group.authorize_port_range(22..22, ip_protocol: "tcp", cidr_ip: "0.0.0.0/0")
          logger.debug("Created temporary security group #{name.dump}.")
        else
          raise("security group already exists: #{name.dump}")
        end
      end

      def delete_security_group(name)
        if security_group = @fog_compute.security_groups.get(name)
          security_group.destroy
          logger.debug("Deleted temporary security group #{name.dump}.")
        end
      end
    end
  end
end

# vim:set ft=ruby :
