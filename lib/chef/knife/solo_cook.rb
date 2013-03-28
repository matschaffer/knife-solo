require 'chef/knife'

require 'knife-solo'
require 'knife-solo/ssh_command'
require 'knife-solo/node_config_command'
require 'knife-solo/tools'
require 'knife-solo/config'

class Chef
  class Knife
    # Approach ported from spatula (https://github.com/trotter/spatula)
    # Copyright 2009, Trotter Cashion
    class SoloCook < Knife
      CHEF_VERSION_CONSTRAINT    = ">=0.10.4" unless defined? CHEF_VERSION_CONSTRAINT

      include KnifeSolo::SshCommand
      include KnifeSolo::NodeConfigCommand
      include KnifeSolo::Tools

      deps do
        require 'chef/cookbook/chefignore'
        require 'pathname'
        KnifeSolo::SshCommand.load_deps
        KnifeSolo::NodeConfigCommand.load_deps
      end

      banner "knife solo cook [USER@]HOSTNAME [JSON] (options)"

      option :chef_check,
        :long        => '--no-chef-check',
        :description => 'Skip the Chef version check on the node',
        :default     => true

      option :skip_chef_check,
        :long        => '--skip-chef-check',
        :description => 'Deprecated. Replaced with --no-chef-check.'

      option :sync_only,
        :long        => '--sync-only',
        :description => 'Only sync the cookbook - do not run Chef'

      option :librarian,
        :long        => '--no-librarian',
        :description => 'Skip librarian-chef install'

      option :why_run,
        :short       => '-W',
        :long        => '--why-run',
        :description => 'Enable whyrun mode'

      option :override_runlist,
        :short       => '-o RunlistItem,RunlistItem...,',
        :long        => '--override-runlist',
        :description => 'Replace current run list with specified items'

      def run
        @solo_config = KnifeSolo::Config.new

        time('Run') do

          if config[:skip_chef_check]
            ui.warn '`--skip-chef-check` is deprecated, please use `--no-chef-check`.'
            config[:chef_check] = false
          end

          validate!

          ui.msg "Running Chef on #{host}..."

          check_chef_version if config[:chef_check]
          generate_node_config
          librarian_install if config_value(:librarian, true)
          rsync_kitchen
          add_patches
          add_solo_config unless using_custom_solorb?
          cook unless config[:sync_only]
        end
      end

      def_delegators :@solo_config,
        :chef_path,
        :using_custom_solorb?,
        :patch_path

      def validate!
        validate_ssh_options!
        @solo_config.validate!
      end

      def chefignore
        @chefignore ||= ::Chef::Cookbook::Chefignore.new("./")
      end

      # cygwin rsync path must be adjusted to work
      def adjust_rsync_path(path)
        path_s = path.to_s
        path_s.gsub(/^(\w):/) { "/cygdrive/#{$1}" }
      end

      def adjust_rsync_path_on_node(path)
        return path unless windows_node?
        adjust_rsync_path(path)
      end

      def adjust_rsync_path_on_client(path)
        return path unless windows_client?
        adjust_rsync_path(path)
      end

      # see http://stackoverflow.com/questions/5798807/rsync-permission-denied-created-directories-have-no-permissions
      def rsync_permissions
        '--chmod=ugo=rwX' if windows_client?
      end

      def rsync_excludes
        (%w{revision-deploys tmp .git .hg .svn .bzr} + chefignore.ignores).uniq
      end

      def debug?
        config[:verbosity] and config[:verbosity] > 0
      end

      # Time a command
      def time(msg)
        return yield unless debug?
        ui.msg "Starting '#{msg}'"
        start = Time.now
        yield
        ui.msg "#{msg} finished in #{Time.now - start} seconds"
      end

      def librarian_install
        if !File.exist? 'Cheffile'
          Chef::Log.debug "Cheffile not found"
        elsif !load_librarian
          ui.warn "Librarian-Chef could not be loaded"
          ui.warn "Please add the librarian gem to your Gemfile or install it manually with `gem install librarian`"
        else
          ui.msg "Installing Librarian cookbooks..."
          Librarian::Action::Resolve.new(librarian_env).run
          Librarian::Action::Install.new(librarian_env).run
        end
      end

      def load_librarian
        begin
          require 'librarian/action'
          require 'librarian/chef'
        rescue LoadError
          false
        else
          true
        end
      end

      def librarian_env
        @librarian_env ||= Librarian::Chef::Environment.new
      end

      def rsync_kitchen
        ui.msg "Syncing kitchen..."
        time('Rsync kitchen') do
          rsync('./', chef_path, '--delete')
        end
      end

      def add_patches
        ui.msg "Adding patches..."
        run_portable_mkdir_p(patch_path)
        Dir[Pathname.new(__FILE__).dirname.join("patches", "*.rb").to_s].each do |patch|
          time(patch) do
            rsync(patch, patch_path)
          end
        end
      end

      def add_solo_config
        ui.msg "Syncing solo config..."
        rsync(KnifeSolo.resource('solo.rb'), chef_path)
      end

      def rsync(source_path, target_path, extra_opts = '')
        cmd = %Q{rsync -rl #{rsync_permissions} --rsh="ssh #{ssh_args}" #{extra_opts} #{rsync_excludes.collect{ |ignore| "--exclude #{ignore} " }.join} #{adjust_rsync_path_on_client(source_path)} :#{adjust_rsync_path_on_node(target_path)}}
        ui.msg cmd if debug?
        system! cmd
      end

      def check_chef_version
        ui.msg "Checking Chef version..."
        unless Gem::Requirement.new(CHEF_VERSION_CONSTRAINT).satisfied_by? Gem::Version.new(chef_version)
          raise "Couldn't find Chef #{CHEF_VERSION_CONSTRAINT} on #{host}. Please run `knife solo prepare #{ssh_args}` to ensure Chef is installed and up to date."
        end
      end

      # Parses "Chef: x.y.z" from the chef-solo version output
      def chef_version
        v = run_command('sudo chef-solo --version').stdout.split(':')
        v[0].strip == 'Chef' ? v[1].strip : ''
      end

      def cook
        ui.msg "Running Chef..."
        cmd = "sudo chef-solo -c #{chef_path}/solo.rb -j #{chef_path}/#{node_config}"
        cmd << " -l debug" if debug?
        cmd << " -N #{config[:chef_node_name]}" if config[:chef_node_name]
        cmd << " -W" if config[:why_run]
        cmd << " -o #{config[:override_runlist]}" if config[:override_runlist]

        result = stream_command cmd
        raise "chef-solo failed. See output above." unless result.success?
      end
    end
  end
end
