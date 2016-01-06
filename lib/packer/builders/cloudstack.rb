#!/usr/bin/env ruby

require 'fog'
require 'uri'
require 'packer/builders/ssh'

module Packer
  module Builders
    class Cloudstack < Ssh # :nodoc:
      def initialize(template, definition, options = {})
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

        @cloudstack_zone_id = resolve_zone(definition)
        @cloudstack_service_offering_id = resolve_service_offering_id(definition)
        @cloudstack_disk_offering_id = resolve_disk_offering(definition)
        @cloudstack_source_template_id = resolve_source_template(definition.merge('zone_id' => @cloudstack_zone_id))
        @cloudstack_network_ids = resolve_network_names(definition.merge('zone_id' => @cloudstack_zone_id))
      end

      def setup(options = {})
        super
        create_key_pair(@cloudstack_key_pair, @ssh_public_key, options)
        create_security_group(@cloudstack_security_group, options)
        create_machine(@cloudstack_machine, options)
      end

      def teardown(options = {})
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

      def build(options = {})
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
            fail('invalid state')
          end
        end
      end

      private

      def create_machine(name, options = {})
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
        info("Creating temporary machine #{name.inspect} as #{create_options.inspect}.")
        return if options[:dry_run]
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

      def delete_machine(name, options = {})
        debug('Deleting temporary machine....')
        return unless name
        if options[:dry_run]
          # nop
        else
          @machine.destroy if @machine
        end
        debug("Deleted temporary machine #{name.inspect}.")
      end

      def create_key_pair(name, public_key, options = {})
        key_pairs = @fog_compute.list_ssh_key_pairs['listsshkeypairsresponse']['sshkeypair']
        if key_pairs.any? { |key_pair| key_pair['name'] == name }
          fail("key pair already exists: #{name.inspect}")
        else
          if options[:dry_run]
            info("Creating temporary key pair #{name.inspect} from #{public_key.inspect}.")
          else
            response = @fog_compute.register_ssh_key_pair(name: name, publickey: File.read(public_key))
            unless response.key?('registersshkeypairresponse')
              fail("failed to register key pair: #{response.inspect}")
            end
          end
          debug("Created temporary key pair #{name.inspect} from #{public_key.inspect}.")
        end
      end

      def delete_key_pair(name, _public_key, options = {})
        debug('Deleting temporary key pair....')
        return if options[:dry_run]
        key_pairs = @fog_compute.list_ssh_key_pairs['listsshkeypairsresponse']['sshkeypair']
        if @fog_compute && key_pairs.any? { |key_pair| key_pair['name'] == name }
          response = @fog_compute.delete_ssh_key_pair(name: name)
          unless response.key?('deletesshkeypairresponse')
            fail("failed to delete key pair: #{response.inspect}")
          end
        end
        debug("Deleted temporary key pair #{name.inspect}.")
      end

      def create_security_group(name, options = {})
        debug('Creating temporary public IP address....')
        return if options[:dry_run]
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

      def delete_security_group(name, options = {})
        debug('Deleting temporary public IP address....')
        return if options[:dry_run]
        response = @fog_compute.disassociate_ip_address(id: @cloudstack_ip_address_id)
        @cloudstack_ip_address_id = nil
        unless response.key?('disassociateipaddressresponse')
          fail("failed to delete temporary ip address: #{response.inspect}")
        end
        debug("Deleted temporary public IP address #{name.inspect}.")
      end

      def resolve_zone(definition, default_value = nil)
        if definition['zone_id']
          definition['zone_id']
        else
          if definition['zone_name']
            name = definition['zone_name'].downcase
            @fog_compute.zones.all.find do |zone|
              name == zone.name.downcase
            end.id
          else
            default_value
          end
        end
      end

      def resolve_service_offering(definition, default_value = nil)
        if definition['service_offering_id']
          definition['service_offering_id']
        else
          if definition['service_offering_name']
            name = definition['service_offering_name'].downcase
            @fog_compute.flavors.all.find do |service_offering|
              name == service_offering.name.downcase
            end.id
          else
            default_value
          end
        end
      end

      def resolve_disk_offering(definition, default_value = nil)
        if definition['disk_offering_id']
          definition['disk_offering_id']
        else
          if definition['disk_offering_name']
            name = definition['disk_offering_name'].downcase
            @fog_compute.disk_offerings.all.find do |disk_offering|
              name == disk_offering.name.downcase
            end.id
          else
            default_value
          end
        end
      end

      def resolve_source_template(definition, default_value = nil)
        if definition['source_template_id']
          definition['source_template_id']
        else
          if definition['source_template_name']
            name = definition['source_template_name'].downcase
            @fog_compute.images.all('templatefilter' => 'featured').find do |t|
              if definition['zone_id']
                name == t.name.downcase && t.zone_id == definition['zone_id']
              else
                name == t.name.downcase
              end
            end.id
          else
            default_value
          end
        end
      end

      def resolve_network_names(definition, default_value = [])
        if definition['network_ids']
          Array(definition['network_ids'])
        else
          if definition['network_names']
            names = Array(names).map(&:downcase)
            @fog_compute.networks.all.select do |network|
              if definition['zone_id']
                names.include?(network.name.downcase) && network.zone_id == definition['zone_id']
              else
                names.include?(network.name.downcase)
              end
            end.map(&:id)
          else
            default_value
          end
        end
      end
    end
  end
end

# vim:set ft=ruby :
