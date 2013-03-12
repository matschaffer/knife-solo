require 'chef/knife'
#require 'knife-solo/ssh_command'
require 'knife-solo/node_config_command'

require 'knife-solo/ssh'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class SoloPrepare < Knife
      #include KnifeSolo::SshCommand
      include KnifeSolo::NodeConfigCommand

      deps do
        require 'knife-solo/bootstraps'
        #KnifeSolo::SshCommand.load_deps
        KnifeSolo::NodeConfigCommand.load_deps
      end

      banner "knife solo prepare [USER@]HOSTNAME [JSON] (options)"

      option :bootstrap_version,
        :long        => '--bootstrap-version VERSION',
        :description => 'The version of Chef to install',
        :proc        => lambda {|v| Chef::Config[:knife][:bootstrap_version] = v}

      option :prerelease,
        :long        => '--prerelease',
        :description => 'Install the pre-release Chef version'

      option :omnibus_url,
        :long        => '--omnibus-url URL',
        :description => 'URL to download install.sh from'

      option :omnibus_options,
        :long        => '--omnibus-options "OPTIONS"',
        :description => 'Pass options to the install.sh script'

      option :omnibus_version,
        :long        => '--omnibus-version VERSION',
        :description => 'Deprecated. Replaced with --bootstrap-check.'

      def run
        if config[:omnibus_version]
          ui.warn '`--omnibus-version` is deprecated, please use `--bootstrap-version`.'
          Chef::Config[:knife][:bootstrap_version] = config[:omnibus_version]
        end

        @ssh_options = {
          :stdout_handler => lambda { |data| stdout_handler(data) },
          :stderr_handler => lambda { |data| stderr_handler(data) },
          :configfile => config[:ssh_config],
          :user => config[:ssh_user],
          :password => config[:ssh_password],
          :password_prompter => lambda { ask_password },
          :identity_file => config[:identity_file],
          :port => config[:port]
        }

        @connection = KnifeSolo::SSH::Connection.new(@name_args.first, @ssh_options)
        @analyzer = KnifeSolo::SSH::Analyzer.new(@connection)
        @runner = KnifeSolo::SSH::Preprocessor.new(@connection, @analyzer)

        bootstrap.bootstrap!
        generate_node_config
      end

      def bootstrap
        ui.msg "Bootstrapping Chef..."
        KnifeSolo::Bootstraps.class_for_operating_system(operating_system).new(self)
      end

      def operating_system
        run_command('uname -s').stdout.strip
      end

      # FOr new SSHCommand
      def run_command(command)
        Chef::Log.debug "Running (#{@connection}): #{command}"
        @runner.run(command)
      end

      def stdout_handler(data)
        Chef::Log.debug "STDOUT (#{@connection}): #{data}"
        puts data if @streaming == true
      end

      def stderr_handler(data)
        Chef::Log.debug "STDERR (#{@connection}): #{data}"
        $stderr.puts data if @streaming == true
      end

      def stream_command(command)
        @streaming = true
        run_command(command)
        @streaming = false
      end

    def ask_password
      ui.ask("Enter the password for #{@connection}: ") do |q|
        q.echo = false
      end
    end

    def host
      @connection.host
    end
    # End new SSHCommand

      def chef_version
        if (v = Chef::Config[:knife][:bootstrap_version])
          v.empty? ? nil : v
        else
          Chef::VERSION
        end
      end
    end
  end
end
