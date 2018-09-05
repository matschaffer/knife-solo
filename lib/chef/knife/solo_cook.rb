require 'chef/knife'

require 'knife-solo/ssh_command'
require 'knife-solo/node_config_command'
require 'knife-solo/tools'

class Chef
  class Knife
    # Approach ported from spatula (https://github.com/trotter/spatula)
    # Copyright 2009, Trotter Cashion
    class SoloCook < Knife

      include KnifeSolo::SshCommand
      include KnifeSolo::NodeConfigCommand
      include KnifeSolo::Tools

      deps do
        require 'chef/cookbook/chefignore'
        require 'knife-solo'
        require 'knife-solo/berkshelf'
        require 'knife-solo/librarian'
        require 'erubis'
        require 'pathname'
        KnifeSolo::SshCommand.load_deps
        KnifeSolo::NodeConfigCommand.load_deps
      end

      banner "knife solo cook [USER@]HOSTNAME [JSONFILE] (options)"

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

      option :sync,
        :long        => '--no-sync',
        :description => 'Do not sync kitchen - only run Chef'

      option :berkshelf,
        :long        => '--no-berkshelf',
        :description => 'Skip berks install'

      option :librarian,
        :long        => '--no-librarian',
        :description => 'Skip librarian-chef install'

      option :secret_file,
        :long        => '--secret-file SECRET_FILE',
        :description => 'A file containing the secret key used to encrypt data bag item values'

      option :why_run,
        :short       => '-W',
        :long        => '--why-run',
        :description => 'Enable whyrun mode'

      option :override_runlist,
        :short       => '-o RunlistItem,RunlistItem...,',
        :long        => '--override-runlist',
        :description => 'Replace current run list with specified items'

      option :provisioning_path,
        :long        => '--provisioning-path path',
        :description => 'Where to store kitchen data on the node'

      option :clean_up,
        :long        => '--clean-up',
        :description => 'Run the clean command after cooking'

      option :legacy_mode,
        :long        => '--legacy-mode',
        :description => 'Run chef-solo in legacy mode'

      option :log_level,
        :short       => '-l LEVEL',
        :long        => '--log-level',
        :description => 'Set the log level for Chef'

      def run
        time('Run') do

          if config[:skip_chef_check]
            ui.warn '`--skip-chef-check` is deprecated, please use `--no-chef-check`.'
            config[:chef_check] = false
          end

          validate!

          ui.msg "Running Chef on #{host}..."

          check_chef_version if config[:chef_check]
          if config_value(:sync, true)
            generate_node_config
            berkshelf_install if config_value(:berkshelf, true)
            librarian_install if config_value(:librarian, true)
            patch_cookbooks_install
            sync_kitchen
            generate_solorb
          end
          cook unless config[:sync_only]

          clean_up if config[:clean_up]
        end
      end

      def validate!
        validate_ssh_options!

        if File.exist? 'solo.rb'
          ui.warn "solo.rb found, but since knife-solo v0.3.0 it is not used any more"
          ui.warn "Please read the upgrade instructions: https://github.com/matschaffer/knife-solo/wiki/Upgrading-to-0.3.0"
        end
      end

      def provisioning_path
        # TODO ~ will likely break on cmd.exe based windows sessions
        config_value(:provisioning_path, '~/chef-solo')
      end

      def sync_kitchen
        ui.msg "Uploading the kitchen..."
        run_portable_mkdir_p(provisioning_path, '0700')

        cookbook_paths.each_with_index do |path, i|
          upload_to_provision_path(path.to_s, "/cookbooks-#{i + 1}", 'cookbook_path')
        end
        upload_to_provision_path(node_config.to_s, 'dna.json')
        upload_to_provision_path(nodes_path, 'nodes')
        upload_to_provision_path(:role_path, 'roles')
        upload_to_provision_path(:data_bag_path, 'data_bags')
        upload_to_provision_path(config[:secret_file] || :encrypted_data_bag_secret, 'data_bag_key')
        upload_to_provision_path(:environment_path, 'environments')
      end

      def ssl_verify_mode
        Chef::Config[:ssl_verify_mode] || :verify_peer
      end

      def solo_legacy_mode
        Chef::Config[:solo_legacy_mode] || false
      end

      def chef_version_constraint
        Chef::Config[:solo_chef_version] || ">=0.10.4"
      end

      def log_level
        config_value(:log_level, Chef::Config[:log_level] || :warn).to_sym
      end

      def enable_reporting
        config_value(:enable_reporting, true)
      end

      def expand_path(path)
        Pathname.new(path).expand_path
      end

      def expanded_config_paths(key)
        Array(Chef::Config[key]).map { |path| expand_path path }
      end

      def cookbook_paths
        @cookbook_paths ||= expanded_config_paths(:cookbook_path)
      end

      def proxy_setting_keys
        [:http_proxy, :https_proxy, :http_proxy_user, :http_proxy_pass, :https_proxy_user, :https_proxy_pass, :no_proxy]
      end

      def proxy_settings
        proxy_setting_keys.inject(Hash.new) do |ret, key|
          ret[key] = Chef::Config[key] if Chef::Config[key]
          ret
        end
      end

      def add_cookbook_path(path)
        path = expand_path path
        cookbook_paths.unshift(path) unless cookbook_paths.include?(path)
      end

      def patch_cookbooks_path
        KnifeSolo.resource('patch_cookbooks')
      end

      def chefignore
        @chefignore ||= ::Chef::Cookbook::Chefignore.new("./")
      end

      # path must be adjusted to work on windows
      def adjust_rsync_path(path, path_prefix)
        path_s = path.to_s
        path_s.gsub(/^(\w):/) { path_prefix + "/#{$1}" }
      end

      def adjust_rsync_path_on_node(path)
        return path unless windows_node?
        adjust_rsync_path(path, config_value(:cygdrive_prefix_remote, '/cygdrive'))
      end

      def adjust_rsync_path_on_client(path)
        return path unless windows_client?
        adjust_rsync_path(path, config_value(:cygdrive_prefix_local, '/cygdrive'))
      end

      def rsync_debug
        '-v' if debug?
      end

      # see http://stackoverflow.com/questions/5798807/rsync-permission-denied-created-directories-have-no-permissions
      def rsync_permissions
        '--chmod=ugo=rwX' if windows_client?
      end

      def rsync_excludes
        (%w{revision-deploys .git .hg .svn .bzr} + chefignore.ignores).uniq
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

      def berkshelf_install
        path = KnifeSolo::Berkshelf.new(config, ui).install
        add_cookbook_path(path) if path
      end

      def librarian_install
        path = KnifeSolo::Librarian.new(config, ui).install
        add_cookbook_path(path) if path
      end

      def generate_solorb
        ui.msg "Generating solo config..."
        template = Erubis::Eruby.new(KnifeSolo.resource('solo.rb.erb').read)
        write(template.result(binding), provisioning_path + '/solo.rb')
      end

      def upload(src, dest)
        rsync(src, dest)
      end

      def upload_to_provision_path(src, dest, key_name = 'path')
        if src.is_a? Symbol
          key_name = src.to_s
          src = Chef::Config[src]
        end

        if src.nil?
          Chef::Log.debug "'#{key_name}' not set"
        elsif !src.is_a?(String)
          ui.error "#{key_name} is not a String: #{src.inspect}"
        elsif !File.exist?(src)
          ui.warn "Local #{key_name} '#{src}' does not exist"
        else
          upload("#{src}#{'/' if File.directory?(src)}", File.join(provisioning_path, dest))
        end
      end

      # TODO probably can get Net::SSH to do this directly
      def write(content, dest)
        file = Tempfile.new(File.basename(dest))
        file.write(content)
        file.close
        upload(file.path, dest)
      ensure
        file.unlink
      end

      def rsync(source_path, target_path, extra_opts = ['--delete-after', '-zt'])
        if config[:ssh_gateway]
          ssh_command = "ssh -TA #{config[:ssh_gateway]} ssh -T -o StrictHostKeyChecking=no #{ssh_args}"
        else
          ssh_command = "ssh #{ssh_args}"
        end

        cmd = ['rsync', '-rL', rsync_debug, rsync_permissions, %Q{--rsh=#{ssh_command}}]
        cmd += extra_opts
        cmd += rsync_excludes.map { |ignore| "--exclude=#{ignore}" }
        cmd += [ adjust_rsync_path_on_client(source_path),
                 ':' + adjust_rsync_path_on_node(target_path) ]

        cmd = cmd.compact

        Chef::Log.debug cmd.inspect
        system!(*cmd)
      end

      def check_chef_version
        ui.msg "Checking Chef version..."
        unless chef_version_satisfies?(chef_version_constraint)
          raise "Couldn't find Chef #{chef_version_constraint} on #{host}. Please run `knife solo prepare #{ssh_args}` to ensure Chef is installed and up to date."
        end
        if node_environment != '_default' && chef_version_satisfies?('<11.6.0')
          ui.warn "Chef version #{chef_version} does not support environments. Environment '#{node_environment}' will be ignored."
        end
      end

      def chef_version_satisfies?(requirement)
        Gem::Requirement.new(requirement).satisfied_by? Gem::Version.new(chef_version)
      end

      # Parses "Chef: x.y.z" from the chef-solo version output
      def chef_version
        # Memoize the version to avoid multiple SSH calls
        @chef_version ||= lambda do
          cmd = %q{sudo chef-solo --version 2>/dev/null | awk '$1 == "Chef:" {print $2}'}
          run_command(cmd).stdout.strip
        end.call
      end

      def cook
        cmd = "sudo chef-solo -c #{provisioning_path}/solo.rb -j #{provisioning_path}/dna.json"
        cmd << " -l debug" if debug?
        cmd << " -N #{config[:chef_node_name]}" if config[:chef_node_name]
        cmd << " -W" if config[:why_run]
        cmd << " -o #{config[:override_runlist]}" if config[:override_runlist]
        if Gem::Version.new(::Chef::VERSION) >= Gem::Version.new("12.10.54")
          cmd << " --legacy-mode" if config[:legacy_mode]
        end

        ui.msg "Running Chef: #{cmd}"

        result = stream_command cmd
        raise "chef-solo failed. See output above." unless result.success?
      end

      def clean_up
        clean = SoloClean.new
        clean.ui = ui
        clean.name_args = @name_args
        clean.config.merge! config
        clean.run
      end

      protected

      def patch_cookbooks_install
        add_cookbook_path(patch_cookbooks_path)
      end
    end
  end
end
