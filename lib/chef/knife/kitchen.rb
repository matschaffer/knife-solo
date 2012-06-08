require 'chef/knife'

class Chef
  class Knife
    class Kitchen < Knife
      include FileUtils

      banner "knife kitchen NAME or initialize current directory with '.'"

      def run
        name = @name_args.first
        mkdir name if name != '.'
        %w(nodes roles data_bags site-cookbooks cookbooks).each do |dir|
          mkdir name + "/#{dir}"
          touch name + "/#{dir}/.gitkeep"
        end
        File.open(name + "/solo.rb", 'w') do |f|
          f << <<-RUBY.gsub(/^ {12}/, '')
            file_cache_path           "/tmp/chef-solo"
            data_bag_path             "/tmp/chef-solo/data_bags"
            encrypted_data_bag_secret "/tmp/chef-solo/data_bag_key"
            cookbook_path             [ "/tmp/chef-solo/site-cookbooks",
                                        "/tmp/chef-solo/cookbooks" ]
            role_path                 "/tmp/chef-solo/roles"
          RUBY
        end
      end
    end
  end
end
