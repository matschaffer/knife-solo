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

      def run
        validate_params!
        super
        bootstrap.bootstrap!
        generate_node_config
      end

      def bootstrap
        ui.msg "Bootstrapping Chef..."
        KnifeSolo::Bootstraps.class_for_operating_system(operating_system()).new(self)
      end

      def generate_node_config
        File.open(node_config, 'w') do |f|
          f.print <<-JSON.gsub(/^\s+/, '')
            { "run_list": [] }
          JSON
        end unless node_config.exist?
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
