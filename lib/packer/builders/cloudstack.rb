#!/usr/bin/env ruby

require 'fog'
require 'uri'
require 'packer/builders/ssh'

module Packer
  module Builders
    class Cloudstack < Ssh
      def initialize(template, definition, options={})
        super
        api_url = URI.parse(definition['api_url'] || ENV['CLOUDSTACK_API_URL'])
        api_key = definition['api_key'] || ENV['CLOUDSTACK_API_KEY']
        secret_key = definition['secret_key'] || ENV['CLOUDSTACK_SECRET_KEY']
        @fog_compute = Fog::Compute.new(
          provider: 'CloudStack',
          cloudstack_api_key: api_key,
          cloudstack_secret_access_key: secret_key,
          cloudstack_scheme: api_url.scheme,
          cloudstack_host: api_url.host,
          cloudstack_port: api_url.port,
          cloudstack_path: api_url.path
        )
        @cloudstack_machine = "packer-#{build_id}"
        @cloudstack_key_pair = "packer-#{build_id}"
        @cloudstack_security_group = "packer-#{build_id}"

        if definition['zone_id']
          @cloudstack_zone_id = definition['zone_id']
        else
          if definition['zone_name']
            zone_name = definition['zone_name'].downcase
            zones = @fog_compute.zones.all.select do |zone|
              zone_name == zone.name.downcase
            end
            @cloudstack_zone_id = zones.first.id
          end
        end

        if definition['service_offering_id']
          @cloudstack_service_offering_id = definition['service_offering_id']
        else
          if definition['service_offering_name']
            service_offering_name = definition['service_offering_name'].downcase
            service_offerings = @fog_compute.flavors.all.select do |service_offering|
              service_offering_name == service_offering.name.downcase
            end
            @cloudstack_service_offering_id = service_offerings.first.id
          end
        end

        if definition['disk_offering_id']
          @cloudstack_disk_offering_id = definition['disk_offering_id']
        else
          if definition['disk_offering_name']
            disk_offering_name = definition['disk_offering_name'].downcase
            disk_offerings = @fog_compute.disk_offerings.all.select do |disk_offering|
              disk_offering_name == disk_offering.name.downcase
            end
            @cloudstack_disk_offering_id = disk_offerings.first.id
          end
        end

        if definition['source_template_id']
          @cloudstack_source_template_id = definition['source_template_id']
        else
          if definition['source_template_name']
            template_name = definition['source_template_name'].downcase
            templates = @fog_compute.images.all('templatefilter' => 'featured').select do |t|
              t.zone_id == @cloudstack_zone_id && template_name == t.name.downcase
            end
            @cloudstack_source_template_id = templates.first.id
          end
        end

        if definition['network_ids']
          @cloudstack_network_ids = definition['network_ids']
        else
          if definition['network_names']
            network_names = definition['network_names'].map { |network_name| network_name.downcase }
            networks = @fog_compute.networks.all.select do |network|
              network.zone_id == @cloudstack_zone_id && network_names.include?(network.name.downcase)
            end
            @cloudstack_network_ids = networks.map { |network| network.id }
          end
        end
      end

      def setup(options={})
        super
        create_key_pair(@cloudstack_key_pair, @ssh_public_key, options)
        create_security_group(@cloudstack_security_group, options)
        create_machine(@cloudstack_machine, options)
      end

      def teardown(options={})
        super
      ensure
        do_with_retry do
          delete_key_pair(@cloudstack_key_pair, @ssh_public_key, options)
        end
        do_with_retry do
          delete_security_group(@cloudstack_security_group, options)
        end
        do_with_retry do
          delete_machine(@cloudstack_machine, options)
        end
      end

      def build(options={})
        super
        sleep(60)
      end

      def hostname
        if options[:dry_run]
          'cloudstack'
        else
          if @machine
            @machine.ssh_ip_address
          else
            raise('invalid state')
          end
        end
      end

      private

      def create_machine(name, options={})
        create_options = {
          flavor_id: @cloudstack_service_offering_id,
          image_id: @cloudstack_source_template_id,
          zone_id: @cloudstack_zone_id,
          display_name: name,
          key_name: @cloudstack_key_pair,
          name: name
        }
        if @cloudstack_disk_offering_id
          create_options[:disk_offering_id] = @cloudstack_disk_offering_id
        end
        if @cloudstack_network_ids
          create_options[:network_ids] = Array(@cloudstack_network_ids).join(',')
        end
        if options[:dry_run]
          info("Creating temporary machine #{name.inspect} as #{create_options.inspect}.")
        else
          debug("Creating temporary machine #{name.inspect} as #{create_options.inspect}.")
          @machine = @fog_compute.servers.create(create_options)
          debug("Waiting for temporary machine #{name.inspect} to be available....")
          @machine.wait_for do
            ready?
          end

          port_forwarding_rule_id = @fog_compute.create_port_forwarding_rule(ipaddressid: @cloudstack_ip_address_id, privateport: 22, protocol: 'TCP', publicport: 22, virtualmachineid: @machine.id, fordisplay: name)['createportforwardingruleresponse']['id']
          begin
            port_forwarding_rule = @fog_compute.port_forwarding_rules.get(port_forwarding_rule_id)
          rescue => error
            warn("failed to get port forwarding rule: #{port_forwarding_rule_id.inspect}: #{error}")
            sleep(rand(10))
            retry
          end
          port_forwarding_rule.wait_for do
            persisted?
          end
          @machine.ssh_ip_address = @cloudstack_ip_address
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
      end

      def delete_machine(name, options={})
        debug('Deleting temporary machine....')
        if name
          if options[:dry_run]
            # nop
          else
            @machine.destroy if @machine
          end
          debug("Deleted temporary machine #{name.inspect}.")
        end
      end

      def create_key_pair(name, public_key, options={})
        key_pairs = @fog_compute.list_ssh_key_pairs['listsshkeypairsresponse']['sshkeypair']
        if key_pairs.any? { |key_pair| key_pair['name'] == name }
          raise("key pair already exists: #{name.inspect}")
        else
          if options[:dry_run]
            info("Creating temporary key pair #{name.inspect} from #{public_key.inspect}.")
          else
            response = @fog_compute.register_ssh_key_pair(name: name, publickey: File.read(public_key))
            unless response.key?('registersshkeypairresponse')
              raise("failed to register key pair: #{response.inspect}")
            end
          end
          debug("Created temporary key pair #{name.inspect} from #{public_key.inspect}.")
        end
      end

      def delete_key_pair(name, public_key, options={})
        debug('Deleting temporary key pair....')
        if name && public_key
          if options[:dry_run]
            # nop
          else
            key_pairs = @fog_compute.list_ssh_key_pairs['listsshkeypairsresponse']['sshkeypair']
            if @fog_compute && key_pairs.any? { |key_pair| key_pair['name'] == name }
              response = @fog_compute.delete_ssh_key_pair(name: name)
              unless response.key?('deletesshkeypairresponse')
                raise("failed to delete key pair: #{response.inspect}")
              end
            end
          end
          debug("Deleted temporary key pair #{name.inspect}.")
        end
      end

      def create_security_group(name, options={})
        debug('Creating temporary public IP address....')
        if options[:dry_run]
          # nop
        else
          @cloudstack_ip_address_id = @fog_compute.associate_ip_address(fordisplay: name, zoneid: @cloudstack_zone_id)['associateipaddressresponse']['id']
          begin
            ip_address = @fog_compute.public_ip_addresses.get(@cloudstack_ip_address_id)
          rescue => error
            warn("failed to get public ip address: #{@cloudstack_ip_address_id.inspect}: #{error}")
            sleep(rand(10))
            retry
          end
          ip_address.wait_for do
            ready?
          end
          @cloudstack_ip_address = ip_address.ip_address
          firewall_rule_id = @fog_compute.create_firewall_rule(ipaddressid: @cloudstack_ip_address_id, protocol: 'TCP', cidrlist: '0.0.0.0/0', endport: 22, fordisplay: name, startport: 22)['createfirewallruleresponse']['id']
          begin
            firewall_rule = @fog_compute.firewall_rules.get(firewall_rule_id)
          rescue => error
            warn("failed to get firewall rule: #{firewall_rule_id.inspect}: #{error}")
            sleep(rand(10))
            retry
          end
          firewall_rule.wait_for do
            persisted?
          end
          debug("Created temporary public IP address #{@cloudstack_ip_address_id.inspect}.")
        end
      end

      def delete_security_group(name, options={})
        debug('Deleting temporary public IP address....')
        if name
          if options[:dry_run]
            # nop
          else
            if @cloudstack_ip_address_id
              response = @fog_compute.disassociate_ip_address(id: @cloudstack_ip_address_id)
              @cloudstack_ip_address_id = nil
              unless response.key?('disassociateipaddressresponse')
                raise("failed to delete temporary ip address: #{response.inspect}")
              end
              debug('Deleted temporary public IP address.')
            end
          end
        end
      end
    end
  end
end

# vim:set ft=ruby :
