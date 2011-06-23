require 'chef/knife'

class Chef
  class Knife
    class Prepare < Knife
      banner "knife prepare HOST"

      def run
        host = @name_args.first
        puts "Preparing #{host}"
      end
    end
  end
end
