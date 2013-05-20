require 'chef/knife'
require 'fileutils'

class Chef
  class Knife
    class SoloInit < Knife
      include FileUtils

      deps do
        require 'knife-solo'
        require 'knife-solo/berkshelf'
        require 'knife-solo/gitignore'
        require 'knife-solo/librarian'
        require 'knife-solo/tools'
      end

      banner "knife solo init DIRECTORY"

      option :git,
        :long => '--no-git',
        :description => 'Do not generate .gitignore',
        :default => true

      option :berkshelf,
        :long        => '--[no-]berkshelf',
        :description => "Generate files for Berkshelf support"

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
        case cookbook_manager
        when :berkshelf
          bootstrap_berkshelf
        when :librarian
          bootstrap_librarian
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
        Chef::Log.debug "Selecting cookbook manager..."
        if (berkshelf = config_value(:berkshelf))
          Chef::Log.debug "Berkshelf selected by configuration"
          :berkshelf
        elsif (librarian = config_value(:librarian))
          Chef::Log.debug "Librarian selected by configuration"
          :librarian
        elsif berkshelf == false && librarian == false
          Chef::Log.debug "All denied by configuration"
          nil
        elsif berkshelf != false && File.exist?(File.join(@base, 'Berksfile'))
          Chef::Log.debug "Berkshelf selected because of existing Berksfile"
          :berkshelf
        elsif librarian != false && File.exist?(File.join(@base, 'Cheffile'))
          Chef::Log.debug "Librarian selected because of existing Cheffile"
          :librarian
        elsif berkshelf != false && KnifeSolo::Berkshelf.gem_installed?
          Chef::Log.debug "Berkshelf selected because of installed gem"
          :berkshelf
        elsif librarian != false && KnifeSolo::Librarian.gem_installed?
          Chef::Log.debug "Librarian selected because of installed gem"
          :librarian
        else
          Chef::Log.debug "Nothing selected"
          # TODO: ui.msg "Recommended to use a cookbook manager"
          nil
        end
      end

      def bootstrap_berkshelf
        ui.msg "Setting up Berkshelf..."
        berksfile = File.join(@base, 'Berksfile')
        unless File.exist?(berksfile)
          File.open(berksfile, 'w') do |f|
            f.puts("site :opscode")
          end
        end
      end

      def bootstrap_librarian
        ui.msg "Setting up Librarian..."
        cheffile = File.join(@base, 'Cheffile')
        unless File.exist?(cheffile)
          File.open(cheffile, 'w') do |f|
            f.puts("site 'http://community.opscode.com/api/v1'")
          end
        end
        gitignore %w[/tmp/librarian/]
      end

      def gitignore(*entries)
        if config[:git]
          KnifeSolo::Gitignore.new(@base).add(*entries)
        end
      end
    end
  end
end
