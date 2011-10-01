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
          f << <<-RUBY.gsub(/^ {12}/, '')
            file_cache_path "/tmp/chef-solo"
            data_bag_path   "/tmp/chef-solo/data_bags"
            cookbook_path   [ "/tmp/chef-solo/site-cookbooks",
                              "/tmp/chef-solo/cookbooks" ]
            role_path       "/tmp/chef-solo/roles"
          RUBY
        end
      end
    end
  end
end
