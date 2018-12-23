require 'net/ssh'

module KnifeSolo
  class SshConnection
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

    def initialize(host, user, connection_options, sudo_password_hook)
      @host = host
      @user = user
      @connection_options = connection_options
      @password_hook = sudo_password_hook
    end

    attr_reader :host, :user, :connection_options

    def session(&block)
      @session ||= begin
        if connection_options[:gateway]
          co = connection_options
          gw_user,gw =  co.delete(:gateway).split '@'
          Net::SSH::Gateway.new(gw, gw_user).ssh(host, user, co, &block)
        else
          Net::SSH.start(host, user, connection_options, &block)
        end
      end
    end

    def password
      @password ||= @password_hook.call
    end

    def run_command(command, output = nil)
      result = ExecResult.new

      begin
        session.open_channel do |channel|
          channel.request_pty
          channel.exec(command) do |_, success|
            raise "ssh.channel.exec failure" unless success

            channel.on_data do |ch, data|  # stdout
              if data =~ /^knife sudo password: /
                ch.send_data("#{password}\n")
              else
                Chef::Log.debug("#{command} stdout: #{data}")
                output << data if output
                result.stdout << data
              end
            end

            channel.on_extended_data do |ch, type, data|
              next unless type == 1
              Chef::Log.debug("#{command} stderr: #{data}")
              output << data if output
              result.stderr << data
            end

            channel.on_request("exit-status") do |ch, data|
              result.exit_code = data.read_long
            end

          end
        end.wait
      rescue Net::SSH::Disconnect
        @session = nil
        Chef::Log.warn("SSH connection is disconnected. Retry #{command} with new SSH session.")
        retry
      end

      result
    end
  end
end
