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
        @amazon_machine = "packer-#{@build_id.slice(0, 16)}"
        @amazon_key_pair = "packer-#{@build_id.slice(0, 16)}"
        @amazon_security_group = "packer-#{@build_id.slice(0, 16)}"
        create_key_pair(@amazon_key_pair, @ssh_public_key, options)
        create_security_group(@amazon_security_group, options)
        create_machine(@amazon_machine, options)
      end

      def teardown(options={})
        super
      ensure
        16.times do |i|
          begin
            delete_key_pair(@amazon_key_pair, @ssh_public_key, options)
            break
          rescue => error
            warn(error)
            sleep(1 + rand(1 << i))
            retry
          end
        end
        16.times do |i|
          begin
            delete_security_group(@amazon_security_group, options)
            break
          rescue => error
            warn(error)
            sleep(1 + rand(1 << i))
            retry
          end
        end
        16.times do |i|
          begin
            delete_machine(@amazon_machine, options)
            break
          rescue => error
            warn(error)
            sleep(1 + rand(1 << i))
            retry
          end
        end
      end

      private
      def create_machine(name, options={})
        raise(NotImplementedError)
      end

      def delete_machine(name, options={})
        raise(NotImplementedError)
      end

      def create_key_pair(name, public_key, options={})
        if @fog_compute.key_pairs.get(name).nil?
          if options[:dry_run]
            info("Creating temporary key pair #{name.dump} from #{public_key.dump}.")
          else
            key_pair = @fog_compute.key_pairs.new(name: name)
            key_pair.public_key = File.read(public_key)
            key_pair.save
          end
          debug("Created temporary key pair #{name.dump} from #{public_key.dump}.")
        else
          raise("key pair already exists: #{name.dump}")
        end
      end

      def delete_key_pair(name, public_key, options={})
        if options[:dry_run]
          info("Deleting temporary key pair #{name.dump}.")
        else
          if key_pair = @fog_compute.key_pairs.get(name)
            key_pair.destroy
          end
        end
        debug("Deleted temporary key pair #{name.dump}.")
      end

      def create_security_group(name, options={})
        if @fog_compute.security_groups.get(name).nil?
          if options[:dry_run]
            info("Creating temporary security group #{name.dump}.")
          else
            security_group = @fog_compute.security_groups.create(name: name, description: name)
            security_group.authorize_port_range(22..22, ip_protocol: "tcp", cidr_ip: "0.0.0.0/0")
          end
          debug("Created temporary security group #{name.dump}.")
        else
          raise("security group already exists: #{name.dump}")
        end
      end

      def delete_security_group(name, options={})
        if options[:dry_run]
          info("Deleting temporary security group #{name.dump}.")
        else
          if security_group = @fog_compute.security_groups.get(name)
            security_group.destroy
          end
        end
        debug("Deleted temporary security group #{name.dump}.")
      end
    end
  end
end

# vim:set ft=ruby :
