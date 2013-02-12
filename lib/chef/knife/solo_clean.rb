require 'chef/knife'

require 'knife-solo/ssh_command'
require 'knife-solo/config'

class Chef
  class Knife
    class SoloClean < Knife
      include KnifeSolo::SshCommand

      banner "knife solo clean [USER@]HOSTNAME"

      def run
        @solo_config = KnifeSolo::Config.new
        validate!
        run_command "rm -rf #{@solo_config.chef_path}"
      end

      def validate!
        validate_ssh_options!
        @solo_config.validate!
      end
    end
  end
end
