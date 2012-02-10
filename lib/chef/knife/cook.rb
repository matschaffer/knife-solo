require 'pathname'

require 'chef/knife'
require 'chef/config'

require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'

class Chef
  class Knife
    # Approach ported from spatula (https://github.com/trotter/spatula)
    # Copyright 2009, Trotter Cashion
    class Cook < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      banner "knife cook [user@]hostname [json] (options)"

      option :skip_chef_check,
        :long => '--skip-chef-check',
        :boolean => true,
        :description => "Skip the version check on the Chef gem"

      option :windows_compat,
        :long => '--windows-compat',
        :description => 'Windows compatibility mode (enable, disable, auto)',
        :default => 'auto'

      def run
        super
        check_syntax
        Chef::Config.from_file('solo.rb')
        check_chef_version unless config[:skip_chef_check]
        rsync_kitchen
        add_patches
        cook
      end

      # todo - move this to SshCommand?
      def is_windows_node?
        run_command("ver").stdout =~ /Windows/i
      end

      def windows_compat?
        # TODO - use a cleaner construct (proper option with choices?)
        @windows_compat ||= case config[:windows_compat]
          when 'enable'; true
          when 'disable'; false
          when 'auto'; is_windows_node?
          else raise "Unsupported windows compatiblity mode"
        end
      end          

      def check_syntax
        ui.msg('Checking cookbook syntax...')
        Dir["**/*.rb"].each do |recipe|
          ok = system "ruby -c #{recipe} >/dev/null 2>&1"
          raise "Syntax error in #{recipe}" if not ok
        end

        Dir["**/*.json"].each do |json|
          begin
            require 'json'
            # parse without instantiating Chef classes
            JSON.parse File.read(json), :create_additions => false
          rescue => error
            raise "Syntax error in #{json}: #{error.message}"
          end
        end
      end

      def node_config
        @name_args[1] || super
      end

      def chef_path
        Chef::Config.file_cache_path
      end

      # cygwin rsync path must be adjusted to work
      def adjust_rsync_path(path)
        return path unless windows_compat?
        path.gsub(/^(\w):/) { "/cygdrive/#{$1}" }
      end

      def patch_path
        Array(Chef::Config.cookbook_path).first + "/chef_solo_patches/libraries"
      end

      def rsync_kitchen
        system %Q{rsync -rlP --rsh="ssh #{ssh_args}" --delete --exclude '.*' ./ :#{adjust_rsync_path(chef_path)}}
      end

      def add_patches
        run_portable_mkdir_p(patch_path)
        Dir[Pathname.new(__FILE__).dirname.join("patches", "*.rb")].each do |patch|
          system %Q{rsync -rlP --rsh="ssh #{ssh_args}" #{patch} :#{adjust_rsync_path(patch_path)}}
        end
      end

      def check_chef_version
        constraint = "~>0.10.4"
        result = run_command <<-BASH
          ruby -rubygems -e "gem 'chef', '#{constraint}'"
        BASH
        raise "The chef gem on #{host} is out of date. Please run `#{$0} prepare #{ssh_args}` to upgrade Chef to #{constraint}." unless result.success?
      end

      def cook
        logging_arg = "-l debug" if config[:verbosity] > 0

        command = []
        command << "sudo" unless windows_compat?
        command << <<-BASH
          chef-solo -c #{chef_path}/solo.rb \
                         -j #{chef_path}/#{node_config} \
                         #{logging_arg}
        BASH
        command = command.join(' ')
        stream_command command
      end
    end
  end
end
