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
      OMNIBUS_EMBEDDED_PATHS     ||= %w[/opt/chef/embedded/bin /opt/opscode/embedded/bin]
      OMNIBUS_EMBEDDED_GEM_PATHS ||= %w[/opt/chef/embedded/lib/ruby/gems/1.9.1 /opt/opscode/embedded/lib/ruby/gems/1.9.1]
      CHEF_VERSION_CONSTRAINT    ||= ">=0.10.4"

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

      option :skip_chef_check,
        :long        => '--skip-chef-check',
        :description => 'Skip the version check on the Chef gem'

      option :sync_only,
        :long        => '--sync-only',
        :description => 'Only sync the cookbook - do not run Chef'

      option :why_run,
        :short       => '-W',
        :long        => '--why-run',
        :description => 'Enable whyrun mode'

      def run
        time('Run') do
          validate!
          Chef::Config.from_file('solo.rb')
          check_chef_version unless config[:skip_chef_check]
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
        result = run_command <<-BASH
          export PATH="#{OMNIBUS_EMBEDDED_PATHS.join(":")}:$PATH"
          export GEM_PATH="#{OMNIBUS_EMBEDDED_GEM_PATHS.join(":")}:$GEM_PATH"
          ruby -rubygems -e "gem 'chef', '#{CHEF_VERSION_CONSTRAINT}'"
        BASH
        raise "Couldn't find Chef #{CHEF_VERSION_CONSTRAINT} on #{host}. Please run `#{$0} prepare #{ssh_args}` to ensure Chef is installed and up to date." unless result.success?
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
