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

      class ConnectionError < StandardError; end

      attr_reader :host, :authentication

      def run
        setup_authentication
        p run_command("sudo grep a b")
      end

      def try_connection(options = {})
        Net::SSH.start(host, user, options) do |ssh|
          ssh.exec!("true")
        end
      end

      def identities
        Dir["#{ENV['HOME']}/.ssh/{id_rsa,id_dsa,identity}"]
      end

      def password
        @password ||= ui.ask("Enter the password for #{user}@#{host}: ") do |q|
          q.echo = false
        end
      end

      def setup_authentication
        host_descriptor = @name_args.first.split('@')
        @host = host_descriptor.pop
        @user = host_descriptor.pop
        @password = config[:ssh_password]

        if @password.nil?
          begin
            @authentication = {}
            try_connection(@authentication)
          rescue Errno::ETIMEDOUT
            raise "Unable to connect to #{host}"
          rescue Net::SSH::AuthenticationFailed
            ui.msg("Unable to login using default keys.")
            @authentication = { :password => password }
          end
        else
          @authentication = { :password => @password }
        end
      end

      def user
        @user || ENV['USER']
      end

      def run_command(command)
        result = { :stdout => "", :stderr => "", :code => nil }
        command = command.sub(/^sudo/, 'sudo -p \'knife sudo password: \'')
        Net::SSH.start(host, user, authentication) do |ssh|
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
