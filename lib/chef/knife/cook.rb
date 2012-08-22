require 'pathname'
require 'rbconfig'

require 'chef/knife'
require 'chef/config'
require 'chef/cookbook/chefignore'

require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'
require 'knife-solo/tools'

class Chef
  class Knife
    # Approach ported from spatula (https://github.com/trotter/spatula)
    # Copyright 2009, Trotter Cashion
    class Cook < Knife
      OMNIBUS_EMBEDDED_PATHS  = ["/opt/chef/embedded/bin", "/opt/opscode/embedded/bin"]
      CHEF_VERSION_CONSTRAINT = ">=0.10.4"

      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand
      include KnifeSolo::Tools

      class WrongCookError < KnifeSolo::KnifeSoloError; end

      banner "knife cook [user@]hostname [json] (options)"

      option :skip_chef_check,
        :long => '--skip-chef-check',
        :boolean => true,
        :description => "Skip the version check on the Chef gem"

      option :sync_only,
        :long => '--sync-only',
        :boolean => false,
        :description => "Only sync the cookbook - do not run Chef"

      option :skip_syntax_check,
        :long => '--skip-syntax-check',
        :boolean => true,
        :description => "Skip Ruby syntax checks"

      option :syntax_check_only,
        :long => '--syntax-check-only',
        :boolean => true,
        :description => "Only run syntax checks - do not run Chef"
      
      def run
        time('Run') do
          validate_params!
          super
          check_syntax unless config[:skip_syntax_check]
          return if config[:syntax_check_only]
          Chef::Config.from_file('solo.rb')
          check_chef_version unless config[:skip_chef_check]
          rsync_kitchen
          add_patches
          cook unless config[:sync_only]
        end
      end

      def check_syntax
        ui.msg('Checking cookbook syntax...')
        chefignore.remove_ignores_from(Dir["**/*.rb"]).each do |recipe|
          ok = quiet_system "ruby -c #{recipe}"
          raise "Syntax error in #{recipe}" if not ok
        end

        chefignore.remove_ignores_from(Dir["**/*.json"]).each do |json|
          begin
            require 'json'
            # parse without instantiating Chef classes
            JSON.parse File.read(json), :create_additions => false
          rescue => error
            raise "Syntax error in #{json}: #{error.message}"
          end
        end
        Chef::Log.info "cookbook and json syntax is ok"
      end

      def node_config
        @name_args[1] || super
      end

      def chef_path
        Chef::Config.file_cache_path
      end

      def chefignore
        @chefignore ||= ::Chef::Cookbook::Chefignore.new("./")
      end

      # cygwin rsync path must be adjusted to work
      def adjust_rsync_path(path)
        path.gsub(/^(\w):/) { "/cygdrive/#{$1}" }
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

      def patch_path
        Array(Chef::Config.cookbook_path).first + "/chef_solo_patches/libraries"
      end

      def rsync_excludes
        (%w{revision-deploys tmp '.*'} + chefignore.ignores).uniq
      end

      # Time a command
      def time(msg)
        return yield if config[:verbosity] == 0
        puts "Starting #{msg}"
        start = Time.now
        yield
        puts "#{msg} finished in #{Time.now - start} seconds"
      end

      def rsync_kitchen
        time('Rsync kitchen') do
          rsync('./', chef_path, '--delete')
        end
      end

      def add_patches
        run_portable_mkdir_p(patch_path)
        Dir[Pathname.new(__FILE__).dirname.join("patches", "*.rb")].each do |patch|
          time(patch) do
            rsync(patch, patch_path)
          end
        end
      end

      def rsync(source_path, target_path, extra_opts = '')
        cmd = %Q{rsync -rl #{rsync_permissions} --rsh="ssh #{ssh_args}" #{extra_opts} #{rsync_excludes.collect{ |ignore| "--exclude #{ignore} " }.join} #{adjust_rsync_path_on_client(source_path)} :#{adjust_rsync_path_on_node(target_path)}}
        puts cmd unless config[:verbosity] == 0
        system! cmd
      end

      def check_chef_version
        ui.msg('Checking Chef version')
        result = run_command <<-BASH
          export PATH="#{OMNIBUS_EMBEDDED_PATHS.join(":")}:$PATH"
          ruby -rubygems -e "gem 'chef', '#{CHEF_VERSION_CONSTRAINT}'"
        BASH
        raise "Couldn't find Chef #{CHEF_VERSION_CONSTRAINT} on #{host}. Please run `#{$0} prepare #{ssh_args}` to ensure Chef is installed and up to date." unless result.success?
      end
      
      def cook
        logging_arg = "-l debug" if config[:verbosity] > 0

        stream_command <<-BASH
          sudo chef-solo -c #{chef_path}/solo.rb \
                         -j #{chef_path}/#{node_config} \
                         #{logging_arg}
        BASH
      end

      def validate_params!
        validate_first_cli_arg_is_a_hostname!(WrongCookError)
      end
      
    end
  end
end
