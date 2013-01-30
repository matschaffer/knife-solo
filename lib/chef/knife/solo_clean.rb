require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'

class Chef
  class Knife
    class SoloClean < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      banner "knife solo clean [USER@]HOSTNAME"

      def run
        validate!
        Chef::Config.from_file('solo.rb')
        run_command "rm -rf #{Chef::Config.file_cache_path}"
      end

      def validate!
        validate_ssh_options!
        validate_kitchen!
      end
    end
  end
end
