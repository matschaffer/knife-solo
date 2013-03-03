require 'chef/knife'

require 'knife-solo/ssh_command'

class Chef
  class Knife
    class SoloClean < Knife
      include KnifeSolo::SshCommand

      banner "knife solo clean [USER@]HOSTNAME"

      option :provisioning_path,
        :long        => '--provisioning-path path',
        :description => 'Where to store kitchen data on the node',
        :default     => '~/chef-solo'
        # TODO de-duplicate this option with solo cook

      def run
        validate!
        run_command "rm -rf #{config[:provisioning_path]}"
      end

      def validate!
        validate_ssh_options!
        @solo_config.validate!
      end
    end
  end
end
