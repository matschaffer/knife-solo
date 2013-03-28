require 'chef/knife/bootstrap'

class Chef
  class Knife
    class Bootstrap

      def self.load_deps
        super
        require 'chef/knife/solo_bootstrap'
        require 'knife-solo/tools'
        SoloBootstrap.load_deps
      end

      option :solo,
        :long        => '--[no-]solo',
        :description => 'Bootstrap using knife-solo'

      # Rename and override run method
      alias_method :orig_run, :run

      def run
        if KnifeSolo::Tools.config_value(config, :solo)
          validate_name_args!

          bootstrap = SoloBootstrap.new
          bootstrap.name_args = @name_args
          bootstrap.config.merge! config
          bootstrap.run
        else
          orig_run
        end
      end
    end
  end
end
