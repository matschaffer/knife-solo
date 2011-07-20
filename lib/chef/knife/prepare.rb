require 'chef/knife'

class Chef
  class Knife
    class Prepare < Knife
      deps do
        require 'net/ssh'
      end

      banner "knife prepare [user@]hostname (options)"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      def run
        p run_command("sudo grep a b")
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
        host_descriptor[:user] || ENV['USER']
      end

      def host
        host_descriptor[:host]
      end

      def ask_password
        @password ||= ui.ask("Enter the password for #{user}@#{host}: ") do |q|
          q.echo = false
        end
      end

      def password
        return @password if @password
        @password = config[:ssh_password] || ask_password
      end

      def try_connection(options = {})
        Net::SSH.start(host, user, options) do |ssh|
          ssh.exec!("true")
        end
      end

      def authentication_method
        return @authentication_method if @authentication_method
        begin
          @authentication_method = {}
          try_connection(@authentication_method)
        rescue Errno::ETIMEDOUT
          raise "Unable to connect to #{host}"
        rescue Net::SSH::AuthenticationFailed
          @authentication_method = { :password => password }
        end
        @authentication_method
      end

      def run_command(command)
        result = { :stdout => "", :stderr => "", :code => nil }
        command = command.sub(/^sudo/, 'sudo -p \'knife sudo password: \'')
        Net::SSH.start(host, user, authentication_method) do |ssh|
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
end
