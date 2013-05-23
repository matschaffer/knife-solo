require 'chef/knife'

require 'knife-solo/ssh_command'
require 'knife-solo/node_config_command'
require 'knife-solo/tools'

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
        require 'knife-solo'
        require 'erubis'
        require 'pathname'
        require 'tempfile'
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

      option :berkshelf,
        :long        => '--no-berkshelf',
        :description => 'Skip berks install'

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

      option :provisioning_path,
        :long        => '--provisioning-path path',
        :description => 'Where to store kitchen data on the node'

      def run
        time('Run') do

          if config[:skip_chef_check]
            ui.warn '`--skip-chef-check` is deprecated, please use `--no-chef-check`.'
            config[:chef_check] = false
          end

          validate!

          ui.msg "Running Chef on #{host}..."

          check_chef_version if config[:chef_check]
          generate_node_config
          berkshelf_install if config_value(:berkshelf, true)
          librarian_install if config_value(:librarian, true)
          sync_kitchen
          generate_solorb
          cook unless config[:sync_only]
          cleanup
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
          upload_to_provision_path(path, "/cookbooks-#{i + 1}", 'cookbook_path')
        end
        upload_to_provision_path(node_config, 'dna.json')
        upload_to_provision_path(nodes_path, 'nodes')
        upload_to_provision_path(:role_path, 'roles')
        upload_to_provision_path(:data_bag_path, 'data_bags')
        upload_to_provision_path(:encrypted_data_bag_secret, 'data_bag_key')
      end

      def expand_path(path)
        Pathname.new(path).expand_path
      end

      def expanded_config_paths(key)
        Array(Chef::Config[key]).map { |path| expand_path path }
      end

      def cookbook_paths
        @cookbook_paths ||= expanded_config_paths(:cookbook_path) + [patch_cookbooks_path]
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

      def rsync_debug
        '-v' if debug?
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

      def berkshelf_install
        if !File.exist? 'Berksfile'
          Chef::Log.debug "Berksfile not found"
        elsif !load_berkshelf
          ui.warn "Berkshelf could not be loaded"
          ui.warn "Please add the berkshelf gem to your Gemfile or install it manually with `gem install berkshelf`"
        else
          path = berkshelf_path
          if path == :tmpdir
            path = @berks_tmp_dir = Dir.mktmpdir('berks-')
          end
          ui.msg "Installing Berkshelf cookbooks to '#{path}'..."
          Berkshelf::Berksfile.from_file(expand_path('Berksfile')).install(:path => path)
          add_cookbook_path path
        end
      end

      def load_berkshelf
        begin
          require 'berkshelf'
        rescue LoadError
          false
        else
          true
        end
      end

      def berkshelf_path
        path = config_value(:berkshelf_path)
        if path.nil?
          ui.warn "`knife[:berkshelf_path]` is not set. Using temporary directory to install Berkshelf cookbooks."
          path = :tmpdir
        end
        path
      end

      def librarian_install
        if !File.exist? 'Cheffile'
          Chef::Log.debug "Cheffile not found"
        elsif !load_librarian
          ui.warn "Librarian-Chef could not be loaded"
          ui.warn "Please add the librarian-chef gem to your Gemfile or install it manually with `gem install librarian-chef`"
        else
          ui.msg "Installing Librarian cookbooks..."
          Librarian::Action::Resolve.new(librarian_env).run
          Librarian::Action::Install.new(librarian_env).run
          add_cookbook_path librarian_env.install_path
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

      def rsync(source_path, target_path, extra_opts = '--delete')
        cmd = %Q{rsync -rl #{rsync_debug} #{rsync_permissions} --rsh="ssh #{ssh_args}" #{extra_opts}}
        cmd << rsync_excludes.map { |ignore| " --exclude '#{ignore}'" }.join
        cmd << %Q{ #{adjust_rsync_path_on_client(source_path)} :#{adjust_rsync_path_on_node(target_path)}}
        Chef::Log.debug cmd
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
        cmd = %q{sudo chef-solo --version 2>/dev/null | awk '$1 == "Chef:" {print $2}'}
        run_command(cmd).stdout.strip
      end

      def cook
        ui.msg "Running Chef..."
        cmd = "sudo chef-solo -c #{provisioning_path}/solo.rb -j #{provisioning_path}/dna.json"
        cmd << " -l debug" if debug?
        cmd << " -N #{config[:chef_node_name]}" if config[:chef_node_name]
        cmd << " -W" if config[:why_run]
        cmd << " -o #{config[:override_runlist]}" if config[:override_runlist]

        result = stream_command cmd
        raise "chef-solo failed. See output above." unless result.success?
      end

      def cleanup
        FileUtils.remove_entry_secure(@berks_tmp_dir) if @berks_tmp_dir
      end
    end
  end
end
