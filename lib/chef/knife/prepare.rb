require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'
require 'knife-solo/bootstraps'
require 'knife-solo/knife_solo_error'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class Prepare < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      class WrongPrepareError < KnifeSolo::KnifeSoloError
        alias :message :to_s
      end

      banner "knife prepare [user@]hostname (options)"

      option :omnibus_version,
        :long => "--omnibus-version VERSION",
        :description => "The version of Omnibus to install"

      option :omnibus_url,
        :long => "--omnibus-url URL",
        :description => "URL to download install.sh from"

      option :omnibus_options,
        :long => "--omnibus-options \"-r -n\"",
        :description => "Pass options to the install.sh script"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to add to node config",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :first_boot_attributes,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes",
        :description => "A JSON string to be added to node config",
        :proc => lambda { |o| JSON.parse(o) },
        :default => {}

      def run
        validate_params!
        super
        bootstrap.bootstrap!
        generate_node_config
      end

      def bootstrap
        KnifeSolo::Bootstraps.class_for_operating_system(operating_system()).new(self)
      end

      def generate_node_config
        if node_config.exist?
          ui.msg "Node config '#{node_config}' already exists"
        else
          ui.msg "Generating node config '#{node_config}'..."
          File.open(node_config, 'w') do |f|
            attributes = config[:first_boot_attributes] || {}
            run_list = { :run_list => config[:run_list] || [] }
            f.print attributes.merge(run_list).to_json
          end
        end
      end

      def operating_system
        @operating_system ||= run_command('uname -s').stdout.strip
      end

      def validate_params!
        validate_first_cli_arg_is_a_hostname!(WrongPrepareError)
      end
    end
  end
end
