require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'
require 'knife-solo/node_config_command'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class Prepare < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand
      include KnifeSolo::NodeConfigCommand

      deps do
        require 'knife-solo/bootstraps'
        KnifeSolo::SshCommand.load_deps
        KnifeSolo::NodeConfigCommand.load_deps
      end

      banner "knife prepare [user@]hostname [json] (options)"

      option :omnibus_version,
        :long => "--omnibus-version VERSION",
        :description => "The version of Omnibus to install"

      option :omnibus_url,
        :long => "--omnibus-url URL",
        :description => "URL to download install.sh from"

      option :omnibus_options,
        :long => "--omnibus-options \"-r -n\"",
        :description => "Pass options to the install.sh script"

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

      def operating_system
        @operating_system ||= run_command('uname -s').stdout.strip
      end

      def validate_params!
        validate_first_cli_arg_is_a_hostname!
      end
    end
  end
end
