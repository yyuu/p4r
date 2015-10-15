#!/usr/bin/env ruby

require "packer/builders/amazon"

module Packer
  module Builders
    class AmazonEbs < Amazon
      def hostname()
        if @machine
          @machine.ssh_ip_address
        else
          "amazon-ebs.example.com"
        end
      end

      private
      def create_machine(name, options={})
        create_options = {
          flavor_id: @definition["instance_type"],
          groups: [@amazon_security_group],
          image_id: @definition["source_ami"],
          key_name: @amazon_key_pair,
        }
        if @definition.key?("launch_block_device_mappings")
          create_options[:block_device_mapping] = @definition["launch_block_device_mappings"].map { |mapping|
            data = {"DeviceName" => mapping["device_name"]}
            if mapping.key?("delete_on_termination")
              data["Ebs.DeleteOnTermination"] = mapping["delete_on_termination"]
            end
            if mapping.key?("volume_size")
              data["Ebs.VolumeSize"] = mapping["volume_size"]
            end
            if mapping.key?("virtual_name")
              data["VirtualName"] = mapping["virtual_name"]
            end
            data
          }
        end
        if options[:dry_run]
          info("Creating temporary machine #{name.dump} as #{create_options.inspect}.")
        else
          debug("Creating temporary machine #{name.dump} as #{create_options.inspect}.")
          @machine = @fog_compute.servers.create(create_options)
          if @definition.key?("ssh_username")
            @machine.username = @definition["ssh_username"]
          end
          debug("Waiting for temporary machine #{name.dump} to be available....")
          @machine.wait_for do
            ready?
          end
          @machine.reload
          debug("Waiting for temporary machine #{name.dump} to be available via ssh....")
          @machine.wait_for do
            sshable?
          end
          @machine.tags.create(key: "Name", value: name)
          debug("Created temporary machine #{name.dump} as #{create_options.inspect}.")
        end
      end

      def delete_machine(name, options={})
        if options[:dry_run]
          info("Deleting temporary machine #{name.dump}.")
        else
          if @machine
            @machine.destroy
            debug("Deleted temporary machine #{name.dump}.")
          end
        end
      end
    end
  end
end

# vim:set ft=ruby :
