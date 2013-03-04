require 'net/ssh'

require 'knife-solo/ssh/exec_result'

module KnifeSolo
  module SSH
    class Connection
      # Indicates malformed consructor arguments
      class ArgumentError < ::ArgumentError; end

      # Indicates issues running exec on channel
      class ChannelFailure < ::StandardError; end

      attr_reader :options
      attr_accessor :sudo_prompt

      # Creates a new ssh connection.
      # Takes openssh client styled target option as a string '[user@]host' and will select defaults similar to those
      # that openssh client uses.
      #
      # Options:
      #
      #   :user - The user to log in as.
      #   :configfile - The ssh config file to read for options (or uses default location).
      #   :password - The account password to use.
      #   :password_prompter - A callable object that returns the account password.
      #
      def initialize(target, options = {})
        @options = options
        @user, @host = parse_connection_target(target)
      end

      def host
        return @host unless @host.nil?
        @host = 'localhost'
      end

      def user
        return @user unless @user.nil?
        @user = options[:user] || config_file_options[:user] || ENV['USER'] || 'root'
      end

      def password
        return @password unless @password.nil?
        @password = options[:password] || options[:password_prompter].call
      end

      # A string of arguments formatted for use with an openssh client
      def ssh_args
        host_arg = [user, host].compact.join('@')
        config_arg = "-F #{options[:configfile]}" if options[:configfile]
        ident_arg = "-i #{options[:identity_file]}" if options[:identity_file]
        port_arg = "-p #{options[:port]}" if options[:port]

        [host_arg, config_arg, ident_arg, port_arg].compact.join(' ')
      end

      def session
        return @session unless @session.nil?
        methods = [ %w(publickey hostbased), %w(password keyboard-interactive) ]

        ssh_options            = config_file_options
        ssh_options[:port]     = options[:port] if options[:port]
        ssh_options[:password] = options[:password] if options[:password]
        ssh_options[:keys]     = [options[:identity_file]] if options[:identity_file]

        begin
          ssh_options[:auth_methods] = methods.shift
          @session = Net::SSH.start(host, user, ssh_options)
        rescue Net::SSH::AuthenticationFailed
          ssh_options[:password] = password
          retry unless methods.empty?
        end
      end

      def run(command)
        result = ExecResult.new

        session.open_channel do |channel|
          channel.request_pty
          channel.on_data do |ch, data|
            handle_stdout(ch, data, result)
          end
          channel.on_extended_data do |ch, type, data|
            next unless type == 1
            handle_stderr(ch, data, result)
          end
          channel.on_request("exit-status") do |ch, data|
            result.exit_code = data.read_long
          end
          channel.exec(command) do |ch, success|
            raise ChannelFailure, "Unable to exec '#{command}'" unless success
          end
        end

        session.loop
        result
      end

      private

      def handle_stdout(ch, data, result)
        if data =~ /^#{sudo_prompt}/
          ch.send_data(password + "\n")
          @strip_next_new_line = true
        else
          if @strip_next_new_line
            data = data[2..-1]
            @strip_next_new_line = false
          end

          options[:stdout_handler].call(data) if options[:stdout_handler]
          result.output << data
          result.stdout << data
        end
      end

      # Handle stderr
      # NOTE: This doesn't typically get used since we have request_pty set
      # and this multiplexes stdout and stderr together.
      # Separating them would probably require a non-TTY version of sudo.
      def handle_stderr(ch, data, result)
        options[:stderr_handler].call(data) if options[:stderr_handler]
        result.output << data
        result.stderr << data
      end

      def config_files
        Array(options[:configfile]) + Net::SSH::Config.default_files
      end

      def config_file_options
        Net::SSH::Config.for(host, config_files)
      end

      def parse_connection_target(target)
        if target.nil? || target.empty? || target[0] == '@'
          raise ArgumentError, 'SSH Target must be [user@]hostname'
        end

        parts = target.rpartition('@')
        user = parts.first unless parts.first.empty?
        host = parts.last unless parts.last.empty?
        [ user, host ]
      end
    end
  end
end
