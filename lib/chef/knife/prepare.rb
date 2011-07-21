require 'chef/knife'
require 'knife-solo/ssh_command'

class Chef
  class Knife
    class Prepare < Knife
      include KnifeSolo::SshCommand

      def run
        p run_command("sudo grep a b")
      end
    end
  end
end
