require 'pathname'

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
        super
        check_syntax unless config[:skip_syntax_check]
        return if config[:syntax_check_only]
        Chef::Config.from_file('solo.rb')
        check_chef_version unless config[:skip_chef_check]
        rsync_kitchen
        add_patches
        cook unless config[:sync_only]
      end

      def check_syntax
        ui.msg('Checking cookbook syntax...')
        chefignore.remove_ignores_from(Dir["**/*.rb"]).each do |recipe|
          ok = system "ruby -c #{recipe} >/dev/null 2>&1"
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
        return path unless windows_node?
        path.gsub(/^(\w):/) { "/cygdrive/#{$1}" }
      end

      def patch_path
        Array(Chef::Config.cookbook_path).first + "/chef_solo_patches/libraries"
      end

      def rsync_exclude
        (%w{revision-deploys tmp '.*'} + chefignore.ignores).uniq
      end

      def rsync_kitchen
        system! %Q{rsync -rl --rsh="ssh #{ssh_args}" --delete #{rsync_exclude.collect{ |ignore| "--exclude #{ignore} " }.join} ./ :#{adjust_rsync_path(chef_path)}}
      end

      def add_patches
        run_portable_mkdir_p(patch_path)
        Dir[Pathname.new(__FILE__).dirname.join("patches", "*.rb")].each do |patch|
          system! %Q{rsync -rl --rsh="ssh #{ssh_args}" #{patch} :#{adjust_rsync_path(patch_path)}}
        end
      end

      def check_chef_version
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
    end
  end
end
