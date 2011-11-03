require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class Prepare < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      banner "knife prepare [user@]hostname (options)"

      def run
        super
        send("#{distro[:type]}_gem_install")
        generate_node_config
      end

      def generate_node_config
        File.open(node_config, 'w') do |f|
          f.print <<-JSON.gsub(/^\s+/, '')
            { "run_list": [] }
          JSON
        end unless node_config.exist?
      end

      def package_list
        @packages.join(' ')
      end

      def zypper_gem_install
        ui.msg("Installing required packages...")
        run_command("sudo zypper --non-interactive install ruby-devel make gcc rsync")
        gem_install
      end

      def emerge_gem_install
        ui.msg("Installing required packages...")
        run_command("sudo USE='-test' ACCEPT_KEYWORDS='~amd64' emerge -u chef")
      end

      def add_yum_repos
        ui.message("Adding EPEL and ELFF...")
        repo_url = "http://download.fedora.redhat.com"
        repo_path = "/pub/epel/5/i386/epel-release-5-4.noarch.rpm"
        result = run_command("sudo rpm -Uvh #{repo_url}#{repo_path}")
        installed = "package epel-release-5-4.noarch is already installed"
        raise result.stderr unless result.success? || result.stdout.match(installed)

        repo_url = "http://download.elff.bravenet.com"
        repo_path = "/5/i386/elff-release-5-3.noarch.rpm"
        result = run_command("sudo rpm -Uvh #{repo_url}#{repo_path}")
        installed = "package elff-release-5-3.noarch is already installed"
        raise result.stderr unless result.success? || result.stdout.match(installed)
      end

      def yum_gem_install
        ui.msg("Installing required packages...")
        @packages = %w(ruby ruby-shadow gcc gcc-c++ ruby-devel wget rsync)
        run_command("sudo yum -y install #{package_list}")
        gem_install
      end

      def debian_gem_install
        ui.msg "Updating apt caches..."
        run_command("sudo apt-get update")

        ui.msg "Installing required packages..."
        @packages = %w(ruby ruby-dev libopenssl-ruby irb
                       build-essential wget ssl-cert rsync)
        run_command <<-BASH
          sudo DEBIAN_FRONTEND=noninteractive apt-get --yes install #{package_list}
        BASH

        gem_install
      end

      def gem_install
        ui.msg "Installing rubygems from source..."
        release = "rubygems-1.8.10"
        file = "#{release}.tgz"
        url = "http://production.cf.rubygems.org/rubygems/#{file}"
        run_command("wget #{url}")
        run_command("tar zxf #{file}")
        run_command("cd #{release} && sudo ruby setup.rb --no-format-executable")
        run_command("sudo rm -rf #{release} #{file}")
        run_command("sudo gem install --no-rdoc --no-ri ruby-shadow chef")
      end

      def issue
        run_command("cat /etc/issue").stdout
      end

      def distro
        @distro ||= case issue
        when %r{Debian GNU/Linux 5}
          {:type => "debian", :version => "lenny"}
        when %r{Debian GNU/Linux 6}
          {:type => "debian", :version => "squeeze"}
        when %r{Debian GNU/Linux wheezy}
          {:type => "debian", :version => "wheezy"}
        when %r{Ubuntu}
          version = run_command("lsb_release -cs").stdout.strip
          {:type => "debian", :version => version}
        when %r{CentOS}
          {:type => "yum", :version => "CentOS"}
        when %r{Red Hat Enterprise Linux}
          {:type => "yum", :version => "Red Hat"}
        when %r{Scientific Linux SL}
          {:type => "yum", :version => "Scientific Linux"}
        when %r{openSUSE 11.4}
          {:type => "zypper", :version => "openSUSE"}
        when %r{This is \\n\.\\O (\\s \\m \\r) \\t}
          {:type => "gentoo", :version => "Gentoo"}
        else
          raise "Distro not recognized from looking at /etc/issue. Please fork https://github.com/matschaffer/knife-solo and add support for your distro."
        end
      end
    end
  end
end
