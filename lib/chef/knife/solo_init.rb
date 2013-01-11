require 'chef/knife'

class Chef
  class Knife
    class SoloInit < Knife
      include FileUtils

      banner "knife solo init DIRECTORY"

      def run
        validate!
        base = @name_args.first
        create_kitchen base
        create_cupboards base, %w(nodes roles data_bags site-cookbooks cookbooks)
        create_solo_config base
      end

      def validate!
        unless @name_args.first
          show_usage
          ui.fatal "You must specify a directory. Use '.' to initialize the current one."
          exit 1
        end
      end

      def create_cupboards(base, dirs)
        dirs.each do |dir|
          cupboard_dir = File.join(base, dir)
          unless File.exist?(cupboard_dir)
            mkdir cupboard_dir
            touch File.join(cupboard_dir, '.gitkeep')
          end
        end
      end

      def create_kitchen(base)
        mkdir base unless base == '.'
      end

      def create_solo_config(base)
        solo_file = File.join(base, 'solo.rb')
        return if File.exist? solo_file

        File.open(solo_file, 'w') do |f|
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
