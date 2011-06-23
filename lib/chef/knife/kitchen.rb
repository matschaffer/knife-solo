require 'chef/knife'

class Chef
  class Knife
    class Kitchen < Knife
      include FileUtils

      banner "knife kitchen NAME"

      def run
        name = @name_args.first
        mkdir name
        mkdir name + "/nodes"
        mkdir name + "/roles"
        mkdir name + "/data_bags"
        mkdir name + "/site-cookbooks"
        mkdir name + "/cookbooks"
      end
    end
  end
end
