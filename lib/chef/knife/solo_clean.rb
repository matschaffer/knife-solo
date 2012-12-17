require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'

class Chef
  class Knife
    class SoloClean < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      banner "knife solo clean [user@]hostname"

      def run
        validate_first_cli_arg_is_a_hostname!
        super
        Chef::Config.from_file('solo.rb')
        run_command "rm -rf #{Chef::Config.file_cache_path}"
      end
    end
  end
end
