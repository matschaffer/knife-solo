require 'chef/knife'

require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'
require 'knife-solo/node_config_command'
require 'knife-solo/tools'

class Chef
  class Knife
    # Approach ported from spatula (https://github.com/trotter/spatula)
    # Copyright 2009, Trotter Cashion
    class SoloCook < Knife
      CHEF_VERSION_CONSTRAINT    = ">=0.10.4" unless defined? CHEF_VERSION_CONSTRAINT

      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand
      include KnifeSolo::NodeConfigCommand
      include KnifeSolo::Tools

      deps do
        require 'chef/cookbook/chefignore'
        require 'librarian/action'
        require 'librarian/chef'
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

      option :why_run,
        :short       => '-W',
        :long        => '--why-run',
        :description => 'Enable whyrun mode'

      def run
        time('Run') do
          if config[:skip_chef_check]
            ui.warn '`--skip-chef-check` is deprecated, please use `--no-chef-check`.'
            config[:chef_check] = false
          end

          validate!
          Chef::Config.from_file('solo.rb')
          check_chef_version if config[:chef_check]
          generate_node_config
          librarian_install
          rsync_kitchen
          add_patches
          cook unless config[:sync_only]
        end
      end

      def validate!
        validate_first_cli_arg_is_a_hostname!
        validate_kitchen!
      end

      def chef_path
        Chef::Config.file_cache_path
      end

      def chefignore
        @chefignore ||= ::Chef::Cookbook::Chefignore.new("./")
      end

      # cygwin rsync path must be adjusted to work
      def adjust_rsync_path(path)
        return path unless windows_node?
        path.gsub(/^(\w):/) { "/cygdrive/#{$1}" }
      end

      def patch_path
        Array(Chef::Config.cookbook_path).first + "/chef_solo_patches/libraries"
      end

      def rsync_exclude
        (%w{revision-deploys tmp '.*'} + chefignore.ignores).uniq
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
        return unless File.exist? 'Cheffile'
        Chef::Log.debug("Installing Librarian cookbooks")
        Librarian::Action::Resolve.new(librarian_env).run
        Librarian::Action::Install.new(librarian_env).run
      end

      def librarian_env
        @librarian_env ||= Librarian::Chef::Environment.new
      end

      def rsync_kitchen
        time('Rsync kitchen') do
          cmd = %Q{rsync -rl --rsh="ssh #{ssh_args}" --delete #{rsync_exclude.collect{ |ignore| "--exclude #{ignore} " }.join} ./ :#{adjust_rsync_path(chef_path)}}
          ui.msg cmd if debug?
          system! cmd
        end
      end

      def add_patches
        run_portable_mkdir_p(patch_path)
        Dir[Pathname.new(__FILE__).dirname.join("patches", "*.rb").to_s].each do |patch|
          time(patch) do
            system! %Q{rsync -rl --rsh="ssh #{ssh_args}" #{patch} :#{adjust_rsync_path(patch_path)}}
          end
        end
      end

      def check_chef_version
        ui.msg "Checking Chef version..."
        unless Gem::Requirement.new(CHEF_VERSION_CONSTRAINT).satisfied_by? Gem::Version.new(chef_version)
          raise "Couldn't find Chef #{CHEF_VERSION_CONSTRAINT} on #{host}. Please run `knife solo prepare #{ssh_args}` to ensure Chef is installed and up to date."
        end
      end

      def chef_version
        v = run_command("sudo chef-solo --version").stdout.split(':') # "Chef: x.y.z"
        v[0] == "Chef" ? v[1].strip : ""
      end

      def cook
        cmd = "sudo chef-solo -c #{chef_path}/solo.rb -j #{chef_path}/#{node_config}"
        cmd << " -l debug" if debug?
        cmd << " -N #{config[:chef_node_name]}" if config[:chef_node_name]
        cmd << " -W" if config[:why_run]

        result = stream_command cmd
        raise "chef-solo failed. See output above." unless result.success?
      end
    end
  end
end
