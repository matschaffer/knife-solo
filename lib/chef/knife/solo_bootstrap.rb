require 'chef/knife'
require 'chef/knife/cook'
require 'chef/knife/prepare'

class Chef
  class Knife
    class SoloBootstrap < Knife
      deps do
        Prepare.load_deps
        Cook.load_deps
      end

      banner "knife solo bootstrap [user@]hostname [json] (options)"

      # Use (some) options from prepare and cook commands
      self.options = Prepare.options
      [:sync_only, :why_run].each { |opt| option opt, Cook.options[opt] }

      def run
        prepare = command_with_same_args(Prepare)
        prepare.run

        cook = command_with_same_args(Cook)
        cook.config[:skip_chef_check] = true
        cook.run
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
