require 'chef/knife'

class Chef
  class Knife
    class SoloInit < Knife
      include FileUtils

      deps do
        require 'knife-solo/gitignore'
      end

      banner "knife solo init DIRECTORY"

      option :git,
        :long => '--no-git',
        :description => 'Do not generate .gitignore',
        :default => true

      option :librarian,
        :long => '--librarian',
        :description => 'Initialize Librarian'

      def run
        @base = @name_args.first
        validate!
        create_kitchen
        create_cupboards %w[nodes roles data_bags site-cookbooks cookbooks]
        librarian_init if config[:librarian]
        create_solo_config
      end

      def validate!
        unless @base
          show_usage
          ui.fatal "You must specify a directory. Use '.' to initialize the current one."
          exit 1
        end
      end

      def create_cupboards(dirs)
        dirs.each do |dir|
          cupboard_dir = File.join(@base, dir)
          unless File.exist?(cupboard_dir)
            mkdir cupboard_dir
            touch File.join(cupboard_dir, '.gitkeep')
          end
        end
      end

      def create_kitchen
        mkdir @base unless @base == '.'
      end

      def create_solo_config
        solo_file = File.join(@base, 'solo.rb')
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

      def librarian_init
        cheffile = File.join(@base, 'Cheffile')
        unless File.exist?(cheffile)
          File.open(cheffile, 'w') do |f|
            f.puts("site 'http://community.opscode.com/api/v1'")
          end
        end
        gitignore %w[/cookbooks/ /tmp/librarian/]
      end

      def gitignore(*entries)
        if config[:git]
          KnifeSolo::Gitignore.new(@base).add(*entries)
        end
      end
    end
  end
end
