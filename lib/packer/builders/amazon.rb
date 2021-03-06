#!/usr/bin/env ruby

require 'digest/sha2'
require 'fog'
require 'packer/builders/ssh'

module Packer
  module Builders
    class Amazon < Ssh # :nodoc:
      def initialize(template, definition, options = {})
        super
        @fog_compute = Fog::Compute.new(
          provider: 'AWS',
          aws_access_key_id: definition['access_key'],
          aws_secret_access_key: definition['secret_key'],
          region: definition['region']
        )
        @amazon_machine = "packer-#{build_id}"
        @amazon_key_pair = "packer-#{build_id}"
        @amazon_security_group = "packer-#{build_id}"
      end

      def setup(options = {})
        super
        create_key_pair(@amazon_key_pair, @ssh_public_key, options)
        create_security_group(@amazon_security_group, options)
        create_machine(@amazon_machine, options)
      end

      def teardown(options = {})
        super
      ensure
        do_with_retry do
          delete_key_pair(@amazon_key_pair, @ssh_public_key, options)
        end
        do_with_retry do
          delete_security_group(@amazon_security_group, options)
        end
        do_with_retry do
          delete_machine(@amazon_machine, options)
        end
      end

      def ssh_hostname
        if @machine
          @machine.ssh_ip_address
        else
          fail('invalid state')
        end
      end

      def ssh_username
        @definition['ssh_username'] || 'root'
      end

      private

      def create_machine(name, options = {})
        create_options = {
          flavor_id: @definition['instance_type'],
          groups: [@amazon_security_groups],
          image_id: @definition['source_ami'],
          key_name: @amazon_key_pair
        }
        if @definition.key?('launch_block_device_mappings')
          create_options[:block_device_mapping] = prepare_block_device_mappings(@definition['launch_block_device_mappings'])
        end
        info("Creating temporary machine #{name.inspect} as #{create_options.inspect}.")
        return if options[:dry_run]
        debug("Creating temporary machine #{name.inspect} as #{create_options.inspect}.")
        @machine = @fog_compute.servers.create(create_options)
        debug("Waiting for temporary machine #{name.inspect} to be available....")
        @machine.wait_for do
          ready?
        end
        @fog_compute.tags.create(key: 'Name', value: name, resource_id: @machine.id, resource_type: 'instance')
        @machine.ssh_options = {
          paranoid: false,
          user_known_hosts_file: '/dev/null'
        }
        if @definition.key?('ssh_username')
          @machine.username = @definition['ssh_username']
        end
        @machine.private_key_path = @ssh_private_key
        debug("Waiting for temporary machine #{name.inspect} to be available via ssh....")
        @machine.wait_for do
          sshable?
        end
        debug("Created temporary machine #{name.inspect} as #{create_options.inspect}.")
      end

      def prepare_block_device_mappings(block_device_mappings = [])
        block_device_mappings.map do |mapping|
          data = { 'DeviceName' => mapping['device_name'] }
          if mapping.key?('delete_on_termination')
            data['Ebs.DeleteOnTermination'] = mapping['delete_on_termination']
          end
          if mapping.key?('volume_size')
            data['Ebs.VolumeSize'] = mapping['volume_size']
          end
          if mapping.key?('virtual_name')
            data['VirtualName'] = mapping['virtual_name']
          end
          data
        end
      end

      def delete_machine(name, options = {})
        debug('Deleting temporary machine....')
        if options[:dry_run]
          # nop
        else
          @machine.destroy if @machine
        end
        debug("Deleted temporary machine #{name.inspect}.")
      end

      def create_key_pair(name, public_key, options = {})
        if @fog_compute.key_pairs.get(name).nil?
          if options[:dry_run]
            info("Creating temporary key pair #{name.inspect} from #{public_key.inspect}.")
          else
            key_pair = @fog_compute.key_pairs.new(name: name)
            key_pair.public_key = File.read(public_key)
            key_pair.save
          end
          debug("Created temporary key pair #{name.inspect} from #{public_key.inspect}.")
        else
          fail("key pair already exists: #{name.inspect}")
        end
      end

      def delete_key_pair(name, _public_key, options = {})
        debug('Deleting temporary key pair....')
        return if options[:dry_run]
        if @fog_compute && (key_pair = @fog_compute.key_pairs.get(name))
          key_pair.destroy
        end
        debug("Deleted temporary key pair #{name.inspect}.")
      end

      def create_security_group(name, options = {})
        if @fog_compute.security_groups.get(name).nil?
          if options[:dry_run]
            info("Creating temporary security group #{name.inspect}.")
          else
            security_group = @fog_compute.security_groups.create(name: name, description: name)
            security_group.authorize_port_range(22..22, ip_protocol: 'tcp', cidr_ip: '0.0.0.0/0')
          end
          debug("Created temporary security group #{name.inspect}.")
        else
          fail("security group already exists: #{name.inspect}")
        end
      end

      def delete_security_group(name, options = {})
        debug('Deleting temporary security group....')
        return if options[:dry_run]
        if @fog_compute && (security_group = @fog_compute.security_groups.get(name))
          security_group.destroy
        end
        debug("Deleted temporary security group #{name.inspect}.")
      end
    end
  end
end

# vim:set ft=ruby :
