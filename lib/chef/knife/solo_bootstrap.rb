require 'chef/knife'
require 'chef/knife/solo_cook'
require 'chef/knife/solo_prepare'

require 'knife-solo/kitchen_command'
require 'knife-solo/ssh_command'

class Chef
  class Knife
    class SoloBootstrap < Knife
      include KnifeSolo::KitchenCommand
      include KnifeSolo::SshCommand

      deps do
        KnifeSolo::SshCommand.load_deps
        SoloPrepare.load_deps
        SoloCook.load_deps
      end

      banner "knife solo bootstrap [USER@]HOSTNAME [JSON] (options)"

      # Use (some) options from prepare and cook commands
      self.options = SoloPrepare.options
      [:librarian, :sync_only, :why_run].each { |opt| option opt, SoloCook.options[opt] }

      def run
        validate!

        prepare = command_with_same_args(SoloPrepare)
        prepare.run

        cook = command_with_same_args(SoloCook)
        cook.config[:chef_check] = false
        cook.run
      end

      def validate!
        validate_ssh_options!
        validate_kitchen!
      end

      def command_with_same_args(klass)
        cmd = klass.new
        cmd.ui = ui
        cmd.name_args = @name_args
        cmd.config = config
        cmd
      end
    end
  end
end
