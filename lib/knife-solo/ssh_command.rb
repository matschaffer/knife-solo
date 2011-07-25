module KnifeSolo
  module SshCommand
    def self.included(other)
      other.instance_eval do
        deps do
          require 'net/ssh'
        end

        banner "knife prepare [user@]hostname (options)"

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
      detect_authentication_method

      host_arg = [user, host].compact.join('@')
      config_arg = "-F #{config[:ssh_config]}" if config[:ssh_config]
      password_arg = "-P #{config[:ssh_password]}" if config[:ssh_password]
      ident_arg = "-i #{config[:ssh_identity]}" if config[:ssh_identity]
      port_arg = "-p #{config[:ssh_port]}" if config[:ssh_port]

      [host_arg, config_arg, password_arg, ident_arg, port_arg].compact.join(' ')
    end

    def run_command(command)
      detect_authentication_method

      result = { :stdout => "", :stderr => "", :code => nil }
      command = command.sub(/^sudo/, 'sudo -p \'knife sudo password: \'')
      Net::SSH.start(host, user, connection_options) do |ssh|
        ssh.open_channel do |channel|
          channel.request_pty
          channel.exec(command) do |ch, success|
            raise "ssh.channel.exec failure" unless success

            channel.on_data do |ch, data|  # stdout
              if data =~ /^knife sudo password: /
                ch.send_data("#{password}\n")
              else
                result[:stdout] << data
              end
            end

            channel.on_extended_data do |ch, type, data|
              next unless type == 1
              result[:stderr] << data
            end

            channel.on_request("exit-status") do |ch, data|
              result[:code] = data.read_long
            end

          end
          ssh.loop
        end
      end
      result
    end
  end
end
