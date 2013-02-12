require 'chef/knife'
require 'knife-solo/ssh_command'

class Chef
  class Knife
    class SoloClean < Knife
      include KnifeSolo::SshCommand

      banner "knife solo clean [USER@]HOSTNAME"

      def run
        validate!
        Chef::Config.from_file('solo.rb')
        run_command "rm -rf #{Chef::Config.file_cache_path}"
      end

      def validate!
        validate_ssh_options!
      end
    end
  end
end
