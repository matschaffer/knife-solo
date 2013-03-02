require 'chef/knife'
require 'fileutils'

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
        create_config
        create_cupboards %w[nodes roles data_bags site-cookbooks cookbooks]
        librarian_init if config[:librarian]
      end

      def validate!
        unless @base
          show_usage
          ui.fatal "You must specify a directory. Use '.' to initialize the current one."
          exit 1
        end
      end

      def create_cupboards(dirs)
        ui.msg "Creating cupboards..."
        dirs.each do |dir|
          cupboard_dir = File.join(@base, dir)
          unless File.exist?(cupboard_dir)
            mkdir cupboard_dir
            touch File.join(cupboard_dir, '.gitkeep')
          end
        end
      end

      def create_kitchen
        ui.msg "Creating kitchen..."
        mkdir @base unless @base == '.'
      end

      def create_config
        ui.msg "Creating knife.rb in kitchen..."
        mkdir File.join(@base, '.chef')
        FileUtils.cp(KnifeSolo.resource('knife.rb'), File.join(@base, '.chef', 'knife.rb'))
      end

      def librarian_init
        ui.msg "Setting up Librarian..."
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
