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
        File.open(name + "/solo.rb", 'w') do |f|
          f << <<-RUBY.gsub(/^\s+/, '')
            file_cache_path "/var/chef-solo"
            cookbook_path "/var/chef-solo/cookbooks"
          RUBY
        end
      end
    end
  end
end
