module KnifeSolo
  module SshCommand

    def self.load_deps
      require 'net/ssh'
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
        deps { KnifeSolo::SshCommand.load_deps } unless @dependency_loader

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

        option :ssh_identity,
          :long        => '--ssh-identity FILE',
          :description => 'Deprecated. Replaced with --identity-file.'

        option :identity_file,
          :short       => '-i IDENTITY_FILE',
          :long        => '--identity-file FILE',
          :description => 'The ssh identity file'

        option :ssh_port,
          :short       => '-p PORT',
          :long        => '--ssh-port PORT',
          :description => 'The ssh port'

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
      if config[:ssh_identity]
        ui.warn '`--ssh-identity` is deprecated, please use `--identity-file`.'
        config[:identity_file] ||= config[:ssh_identity]
      end
      unless first_cli_arg_is_a_hostname?
        show_usage
        ui.fatal "You must specify [<user>@]<hostname> as the first argument"
        exit 1
      end
      if config[:ssh_user]
        host_descriptor[:user] ||= config[:ssh_user]
      end
    end

    def host_descriptor
      return @host_descriptor if @host_descriptor
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
      Net::SSH.start(host, user, connection_options) do |ssh|
        ssh.exec!("true")
      end
    end

    def config_file_options
      Net::SSH::Config.for(host, config_files)
    end

    def connection_options
      options = config_file_options
      options[:port] = config[:ssh_port] if config[:ssh_port]
      options[:password] = config[:ssh_password] if config[:ssh_password]
      options[:keys] = [config[:identity_file]] if config[:identity_file]
      if !config[:host_key_verify]
        options[:paranoid] = false
        options[:user_known_hosts_file] = "/dev/null"
      end
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
      host_arg = [user, host].compact.join('@')
      config_arg = "-F #{config[:ssh_config]}" if config[:ssh_config]
      ident_arg = "-i #{config[:identity_file]}" if config[:identity_file]
      port_arg = "-p #{config[:ssh_port]}" if config[:ssh_port]      
      knownhosts_arg  =  "-o UserKnownHostsFile=#{connection_options[:user_known_hosts_file]}" if config[:host_key_verify] == false
      stricthosts_arg = "-o StrictHostKeyChecking=no" if config[:host_key_verify] == false


      [host_arg, config_arg, ident_arg, port_arg, knownhosts_arg, stricthosts_arg].compact.join(' ')
    end

    def sudo_command
      config[:sudo_command]
    end

    def startup_script
      config[:startup_script]
    end

    class ExecResult
      attr_accessor :stdout, :stderr, :exit_code

      def initialize(exit_code = nil)
        @exit_code = exit_code
        @stdout = ""
        @stderr = ""
      end

      def success?
        exit_code == 0
      end

      # Helper to use when raising exceptions since some operations
      # (e.g., command not found) error on stdout
      def stderr_or_stdout
        return stderr unless stderr.empty?
        stdout
      end
    end

    def windows_node?
      return @windows_node unless @windows_node.nil?
      @windows_node = run_command('ver', :process_sudo => false).stdout =~ /Windows/i
      Chef::Log.debug("Windows node detected") if @windows_node
      @windows_node
    end

    def sudo_available?
      return @sudo_available unless @sudo_available.nil?
      @sudo_available = run_command('sudo -V', :process_sudo => false).success?
      Chef::Log.debug("`sudo` not available on #{host}") unless @sudo_available
      @sudo_available
    end

    def process_sudo(command)
      if sudo_command
        Chef::Log.debug("Using replacement sudo command: #{sudo_command}")
        replacement = sudo_command
      elsif sudo_available?
        replacement = 'sudo -p \'knife sudo password: \''
      else
        replacement = ''
      end
      command.gsub(/sudo/, replacement)
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
      result = ExecResult.new

      command = processed_command(command, options)
      Chef::Log.debug("Running processed command #{command}")

      Net::SSH.start(host, user, connection_options) do |ssh|
        ssh.open_channel do |channel|
          channel.request_pty
          channel.exec(command) do |ch, success|
            raise "ssh.channel.exec failure" unless success

            channel.on_data do |ch, data|  # stdout
              if data =~ /^knife sudo password: /
                ch.send_data("#{password}\n")
              else
                Chef::Log.debug("#{command} stdout: #{data}")
                ui.stdout << data if options[:streaming]
                result.stdout << data
              end
            end

            channel.on_extended_data do |ch, type, data|
              next unless type == 1
              Chef::Log.debug("#{command} stderr: #{data}")
              ui.stderr << data if options[:streaming]
              result.stderr << data
            end

            channel.on_request("exit-status") do |ch, data|
              result.exit_code = data.read_long
            end

          end
          ssh.loop
        end
      end
      result
    end

    # Runs commands from the specified array until successful.
    # Returns the result of the successful command or an ExecResult with
    # exit_code 1 if all fail.
    def run_with_fallbacks(commands, options = {})
      commands.each do |command|
        result = run_command(command, options)
        return result if result.success?
      end
      ExecResult.new(1)
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
