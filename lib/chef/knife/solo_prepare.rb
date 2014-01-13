require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/node_config_command'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class SoloPrepare < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::NodeConfigCommand

      deps do
        require 'knife-solo/bootstraps'
        KnifeSolo::SshCommand.load_deps
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
        :description => 'Deprecated. Replaced with --bootstrap-version.'

      option :hint,
        :long        => '--hint HINT_NAME[=HINT_FILE]',
        :description => 'Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.',
        :proc        => Proc.new { |h|
          Chef::Config[:knife][:hints] ||= Hash.new
          name, path = h.split("=")
          Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new  }

      def run
        if config[:omnibus_version]
          ui.warn '`--omnibus-version` is deprecated, please use `--bootstrap-version`.'
          Chef::Config[:knife][:bootstrap_version] = config[:omnibus_version]
        end

        validate!
        bootstrap.bootstrap!
        generate_node_config
      end

      def validate!
        validate_ssh_options!
      end

      def bootstrap
        ui.msg "Bootstrapping Chef..."
        KnifeSolo::Bootstraps.class_for_operating_system(operating_system).new(self)
      end

      def operating_system
        run_command('uname -s').stdout.strip
      end

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
