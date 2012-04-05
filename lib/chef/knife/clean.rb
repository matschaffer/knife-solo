require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'

class Chef
  class Knife
    class Clean < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      banner "knife clean [user@]hostname"

      def run
        super
        Chef::Config.from_file('solo.rb')
        run_command "rm -rf #{Chef::Config.file_cache_path}"
      end
    end
  end
end
