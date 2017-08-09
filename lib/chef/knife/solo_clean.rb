require 'chef/knife'

require 'knife-solo/ssh_command'

class Chef
  class Knife
    class SoloClean < Knife
      include KnifeSolo::SshCommand

      deps do
        require 'knife-solo/tools'
        KnifeSolo::SshCommand.load_deps
      end

      banner "knife solo clean [USER@]HOSTNAME"

      option :provisioning_path,
        :long        => '--provisioning-path path',
        :description => 'Where to store kitchen data on the node'
        # TODO de-duplicate this option with solo cook

      option :clean_up_command,
        :long        => '--clean-up-command "custom command"',
        :description => 'What command to run to remove provisioning path'

      def run
        validate!
        ui.msg "Cleaning up #{host}..."
        run_command "#{clean_up_command} #{provisioning_path}"
      end

      def validate!
        validate_ssh_options!
      end

      def provisioning_path
        # TODO de-duplicate this method with solo cook
        KnifeSolo::Tools.config_value(config, :provisioning_path, '~/chef-solo')
      end

      def clean_up_command
        # TODO de-duplicate this method with solo cook
        KnifeSolo::Tools.config_value(config, :clean_up_command, 'rm -rf')
      end
    end
  end
end
