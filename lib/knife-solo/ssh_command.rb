module KnifeSolo
  module SshCommand

    def self.load_deps
      require 'knife-solo/ssh_connection'
      require 'knife-solo/tools'
      require 'net/ssh'
      require 'net/ssh/gateway'
    end

    def self.included(other)
      other.class_eval do
        # Lazy load our dependencies if the including class did not call
        # Knife#deps yet. Later calls to #deps override previous ones, so if
        # the outer class calls it, it should also call our #load_deps, i.e:
        #
        #   Include KnifeSolo::SshCommand
        #
        #   dep do
        #     require 'foo'
        #     require 'bar'
        #     KnifeSolo::SshCommand.load_deps
        #   end
        #
        deps { KnifeSolo::SshCommand.load_deps } unless defined?(@dependency_loader)

        option :ssh_config,
          :short       => '-F CONFIG_FILE',
          :long        => '--ssh-config-file CONFIG_FILE',
          :description => 'Alternate location for ssh config file'

        option :ssh_user,
          :short       => '-x USERNAME',
          :long        => '--ssh-user USERNAME',
          :description => 'The ssh username'

        option :ssh_password,
          :short       => '-P PASSWORD',
          :long        => '--ssh-password PASSWORD',
          :description => 'The ssh password'

        option :ssh_gateway,
          :long        => '--ssh-gateway GATEWAY',
          :description => 'The ssh gateway'

        option :ssh_control_master,
          :long => '--ssh-control-master SETTING',
          :description => 'Control master setting to use when running rsync (use "auto" to enable)',
          :default => 'no'

        option :identity_file,
          :long => "--identity-file IDENTITY_FILE",
          :description => "The SSH identity file used for authentication. [DEPRECATED] Use --ssh-identity-file instead."

        option :ssh_identity_file,
          :short => "-i IDENTITY_FILE",
          :long => "--ssh-identity-file IDENTITY_FILE",
          :description => "The SSH identity file used for authentication"

        option :forward_agent,
          :long        => '--forward-agent',
          :description => 'Forward SSH authentication. Adds -E to sudo, override with --sudo-command.',
          :boolean     => true,
          :default     => false

        option :ssh_port,
          :short       => '-p PORT',
          :long        => '--ssh-port PORT',
          :description => 'The ssh port'

        option :ssh_keepalive,
          :long        => '--[no-]ssh-keepalive',
          :description => 'Use ssh keepalive',
          :default     => true

        option :ssh_keepalive_interval,
          :long        => '--ssh-keepalive-interval SECONDS',
          :description => 'The ssh keepalive interval',
          :default     => 300,
          :proc        => Proc.new { |v| v.to_i }

        option :startup_script,
          :short       => '-s FILE',
          :long        => '--startup-script FILE',
          :description => 'The startup script on the remote server containing variable definitions'

        option :sudo_command,
          :long        => '--sudo-command SUDO_COMMAND',
          :description => 'The command to use instead of sudo for admin privileges'

        option :host_key_verify,
          :long => "--[no-]host-key-verify",
          :description => "Verify host key, enabled by default.",
          :boolean => true,
          :default => true

      end
    end

    def first_cli_arg_is_a_hostname?
      @name_args.first =~ /\A([^@]+(?>@)[^@]+|[^@]+?(?!@))\z/
    end

    def validate_ssh_options!
      if config[:identity_file]
        ui.warn '`--identity-file` is deprecated, please use `--ssh-identity-file`.'
      end
      unless first_cli_arg_is_a_hostname?
        show_usage
        ui.fatal "You must specify [<user>@]<hostname> as the first argument"
        exit 1
      end
      if config[:ssh_user]
        host_descriptor[:user] ||= config[:ssh_user]
      end

      # NOTE: can't rely on default since it won't get called when invoked via knife bootstrap --solo
      if config[:ssh_keepalive_interval] && config[:ssh_keepalive_interval] <= 0
        ui.fatal '`--ssh-keepalive-interval` must be a positive number'
        exit 1
      end
    end

    def host_descriptor
      return @host_descriptor if defined?(@host_descriptor)
      parts = @name_args.first.split('@')
      @host_descriptor = {
        :host => parts.pop,
        :user => parts.pop
      }
    end

    def user
      host_descriptor[:user] || config_file_options[:user] || ENV['USER']
    end

    def host
      host_descriptor[:host]
    end

    def ask_password
      ui.ask("Enter the password for #{user}@#{host}: ") do |q|
        q.echo = false
        q.whitespace = :chomp
      end
    end

    def password
      config[:ssh_password] ||= ask_password
    end

    def try_connection
      ssh_connection.session do |ssh|
        ssh.exec!("true")
      end
    end

    def config_file_options
      Net::SSH::Config.for(host, config_files)
    end

    def identity_file
      config[:ssh_identity] || config[:identity_file] || config[:ssh_identity_file]
    end

    def connection_options
      options = config_file_options
      options[:port] = config[:ssh_port] if config[:ssh_port]
      options[:password] = config[:ssh_password] if config[:ssh_password]
      options[:keys] = [identity_file] if identity_file
      options[:gateway] = config[:ssh_gateway] if config[:ssh_gateway]
      options[:forward_agent] = true if config[:forward_agent]
      if !config[:host_key_verify]
        options[:paranoid] = false
        options[:user_known_hosts_file] = "/dev/null"
      end
      if config[:ssh_keepalive]
        options[:keepalive] = config[:ssh_keepalive]
        options[:keepalive_interval] = config[:ssh_keepalive_interval]
      end
      # Respect users' specification of config[:ssh_config]
      # Prevents Net::SSH itself from applying the default ssh_config files.
      options[:config] = false
      options
    end

    def config_files
      Array(config[:ssh_config] || Net::SSH::Config.default_files)
    end

    def detect_authentication_method
      return @detected if @detected
      begin
        try_connection
      rescue Errno::ETIMEDOUT
        raise "Unable to connect to #{host}"
      rescue Net::SSH::AuthenticationFailed
        # Ensure the password is set or ask for it immediately
        password
      end
      @detected = true
    end

    def ssh_args
      args = []

      args << [user, host].compact.join('@')

      args << "-F #{config[:ssh_config]}" if config[:ssh_config]
      args << "-i #{identity_file}" if identity_file
      args << "-o ForwardAgent=yes" if config[:forward_agent]
      args << "-p #{config[:ssh_port]}" if config[:ssh_port]
      args << "-o UserKnownHostsFile=#{connection_options[:user_known_hosts_file]}" if config[:host_key_verify] == false
      args << "-o StrictHostKeyChecking=no" if config[:host_key_verify] == false
      args << "-o ControlMaster=auto -o ControlPath=#{ssh_control_path} -o ControlPersist=3600" unless config[:ssh_control_master] == "no"

      args.join(' ')
    end

    def ssh_control_path
      dir = File.join(ENV['HOME'], '.chef', 'knife-solo-sockets')
      FileUtils.mkdir_p(dir)
      File.join(dir, '%C')
    end

    def custom_sudo_command
      if sudo_command=config[:sudo_command]
        Chef::Log.debug("Using replacement sudo command: #{sudo_command}")
        return sudo_command
      end
    end

    def standard_sudo_command
      return unless sudo_available?
      if config[:forward_agent]
        return 'sudo -E -p \'knife sudo password: \''
      else
        return 'sudo -p \'knife sudo password: \''
      end
    end

    def sudo_command
      custom_sudo_command || standard_sudo_command || ''
    end

    def startup_script
      config[:startup_script]
    end

    def windows_node?
      return @windows_node unless @windows_node.nil?
      @windows_node = run_command('ver', :process_sudo => false).stdout =~ /Windows/i
      if @windows_node
        Chef::Log.debug("Windows node detected")
      else
        @windows_node = false
      end
      @windows_node
    end

    def sudo_available?
      return @sudo_available unless @sudo_available.nil?
      @sudo_available = run_command('sudo -V', :process_sudo => false).success?
      Chef::Log.debug("`sudo` not available on #{host}") unless @sudo_available
      @sudo_available
    end

    def process_sudo(command)
      command.gsub(/sudo/, sudo_command)
    end

    def process_startup_file(command)
      command.insert(0, "source #{startup_script} && ")
    end

    def stream_command(command)
      run_command(command, :streaming => true)
    end

    def processed_command(command, options = {})
      command = process_sudo(command) if options[:process_sudo]
      command = process_startup_file(command) if startup_script
      command
    end

    def run_command(command, options = {})
      defaults = {:process_sudo => true}
      options = defaults.merge(options)

      detect_authentication_method

      Chef::Log.debug("Initial command #{command}")

      command = processed_command(command, options)
      Chef::Log.debug("Running processed command #{command}")

      output = ui.stdout if options[:streaming]

      @connection ||= ssh_connection
      @connection.run_command(command, output)
    end

    def ssh_connection
       SshConnection.new(host, user, connection_options, method(:password))
    end

    # Runs commands from the specified array until successful.
    # Returns the result of the successful command or an ExecResult with
    # exit_code 1 if all fail.
    def run_with_fallbacks(commands, options = {})
      commands.each do |command|
        result = run_command(command, options)
        return result if result.success?
      end
      SshConnection::ExecResult.new(1)
    end

    # TODO:
    # - move this to a dedicated "portability" module?
    # - use ruby in all cases instead?
    def run_portable_mkdir_p(folder, mode = nil)
      if windows_node?
        # no mkdir -p on windows - fake it
        run_command %Q{ruby -e "require 'fileutils'; FileUtils.mkdir_p('#{folder}', :mode => #{mode})"}
      else
        mode_option = (mode.nil? ? "" : "-m #{mode}")
        run_command "mkdir -p #{mode_option} #{folder}"
      end
    end

  end
end
