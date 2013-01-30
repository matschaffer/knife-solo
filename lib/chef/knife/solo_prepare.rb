require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'
require 'knife-solo/node_config_command'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class SoloPrepare < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand
      include KnifeSolo::NodeConfigCommand

      deps do
        require 'knife-solo/bootstraps'
        KnifeSolo::SshCommand.load_deps
        KnifeSolo::NodeConfigCommand.load_deps
      end

      banner "knife solo prepare [USER@]HOSTNAME [JSON] (options)"

      option :omnibus_url,
        :long        => '--omnibus-url URL',
        :description => 'URL to download install.sh from'

      option :omnibus_options,
        :long        => '--omnibus-options "OPTIONS"',
        :description => 'Pass options to the install.sh script'

      option :omnibus_version,
        :long        => '--omnibus-version VERSION',
        :description => 'The version of Omnibus to install'

      def run
        if config[:omnibus_version]
          config[:omnibus_options] = "#{config[:omnibus_options]} -v #{config[:omnibus_version]}".strip
        end

        validate!
        bootstrap.bootstrap!
        generate_node_config
      end

      def validate!
        validate_ssh_options!
        validate_kitchen!
      end

      def bootstrap
        ui.msg "Bootstrapping Chef..."
        KnifeSolo::Bootstraps.class_for_operating_system(operating_system).new(self)
      end

      def operating_system
        run_command('uname -s').stdout.strip
      end
    end
  end
end
