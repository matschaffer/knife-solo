require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'

class Chef
  class Knife
    class WashUp < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      banner "knife wash_up [user@]hostname"

      def run
        super
        Chef::Config.from_file('solo.rb')
        run_command "rm -rf #{Chef::Config.file_cache_path}"
      end
    end
  end
end
