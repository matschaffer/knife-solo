require 'pathname'

module KnifeSolo
  module SshCommand
    def self.included(other)
      other.instance_eval do
        deps do
          require 'net/ssh'
        end

        option :ssh_config,
          :short => "-F configfile",
          :long => "--ssh-config-file configfile",
          :description => "Alternate location for ssh config file"

        option :ssh_password,
          :short => "-P PASSWORD",
          :long => "--ssh-password PASSWORD",
          :description => "The ssh password"

        option :ssh_identity,
          :short => "-i FILE",
          :long => "--ssh-identity FILE",
          :description => "The ssh identity file"

        option :ssh_port,
          :short => "-p FILE",
          :long => "--ssh-port FILE",
          :description => "The ssh port"

        option :startup_script,
          :short => "-s FILE",
          :long => "--startup-script FILE",
          :description => "The startup script on the remote server containing variable definitions"
      end
    end

    def node_config
      Pathname.new("nodes/#{host}.json")
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
      options[:keys] = [config[:ssh_identity]] if config[:ssh_identity]
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
      ident_arg = "-i #{config[:ssh_identity]}" if config[:ssh_identity]
      port_arg = "-p #{config[:ssh_port]}" if config[:ssh_port]

      [host_arg, config_arg, ident_arg, port_arg].compact.join(' ')
    end

    def startup_script
      config[:startup_script]
    end

    class ExecResult
      attr_accessor :stdout, :stderr, :exit_code

      def initialize
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
      if sudo_available?
        replacement = 'sudo -p \'knife sudo password: \''
      else
        replacement = ''
      end
      command.sub(/^\s*sudo/, replacement)
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

    def run_command(command, options={})
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

    # TODO:
    # - move this to a dedicated "portability" module?
    # - use ruby in all cases instead?
    def run_portable_mkdir_p(folder)
      if windows_node?
        # no mkdir -p on windows - fake it
        run_command %Q{ruby -e "require 'fileutils'; FileUtils.mkdir_p('#{folder}')"}
      else
        run_command "mkdir -p #{folder}"
      end
    end

  end
end
