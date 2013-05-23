require 'chef/knife'
require 'fileutils'

class Chef
  class Knife
    class SoloInit < Knife
      include FileUtils

      deps do
        require 'knife-solo'
        require 'knife-solo/cookbook_manager_selector'
        require 'knife-solo/gitignore'
        require 'knife-solo/tools'
      end

      banner "knife solo init DIRECTORY"

      option :git,
        :long        => '--no-git',
        :description => 'Do not generate .gitignore'
        :default     => true

      option :berkshelf,
        :long        => '--[no-]berkshelf',
        :description => 'Generate files for Berkshelf support'

      option :librarian,
        :long        => '--[no-]librarian',
        :description => 'Generate files for Librarian support'

      def run
        @base = @name_args.first
        validate!
        create_kitchen
        create_config
        create_cupboards %w[nodes roles data_bags site-cookbooks cookbooks]
        gitignore %w[/cookbooks/]
        if (cm = cookbook_manager)
          cm.bootstrap(@base)
        end
      end

      def validate!
        unless @base
          show_usage
          ui.fatal "You must specify a directory. Use '.' to initialize the current one."
          exit 1
        end
      end

      def config_value(key, default = nil)
        KnifeSolo::Tools.config_value(config, key, default)
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
        mkdir_p File.join(@base, '.chef')
        knife_rb = File.join(@base, '.chef', 'knife.rb')
        unless File.exist?(knife_rb)
          cp KnifeSolo.resource('knife.rb'), knife_rb
        end
      end

      def cookbook_manager
        KnifeSolo::CookbookManagerSelector.new(config, ui).select(@base)
      end

      def gitignore(*entries)
        if config[:git]
          KnifeSolo::Gitignore.new(@base).add(*entries)
        end
      end
    end
  end
end
