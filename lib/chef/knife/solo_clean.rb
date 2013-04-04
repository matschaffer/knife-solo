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

      def run
        validate!
        run_command "rm -rf #{provisioning_path}"
      end

      def validate!
        validate_ssh_options!
        @solo_config.validate!
      end

      def provisioning_path
        # TODO de-duplicate this method with solo cook
        KnifeSolo::Tools.config_value(config, :provisioning_path, '~/chef-solo')
      end
    end
  end
end
