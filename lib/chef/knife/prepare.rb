require 'chef/knife'
require 'knife-solo/ssh_command'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class Prepare < Knife
      include KnifeSolo::SshCommand

      def run
        send("#{distro[:type]}_gem_install")
      end

      def emerge_gem_install
        ui.msg("Installing required packages...")
        run_command("sudo USE='-test' ACCEPT_KEYWORDS='~amd64' emerge -u chef")
      end

      def add_rpm_repos
        ui.message("Adding EPEL and ELFF...")
        repo_url = "http://download.fedora.redhat.com"
        repo_path = "/pub/epel/5/i386/epel-release-5-4.noarch.rpm"
        result = run_command("sudo rpm -Uvh #{repo_url}#{repo_path}")
        installed = "package epel-release-5-4.noarch is already installed"
        # TODO error checking
        #    if output.failed and installed not in output:
        #        abort(output)

        repo_url = "http://download.elff.bravenet.com"
        repo_path = "/5/i386/elff-release-5-3.noarch.rpm"
        result = run_command("sudo rpm -Uvh #{repo_url}#{repo_path}")
        installed = "package elff-release-5-3.noarch is already installed"
        # TODO error checking
        #    if output.failed and installed not in output:
        #        abort(output)
      end

      def rpm_gem_install
        ui.msg("Installing required packages...")
        packages = %w(ruby ruby-shadow gcc gcc-c++ ruby-devel wget)
        run_command("sudo yum -y install #{packages.join(' ')}")
        gem_install
      end

      def debian_gem_install
        packages = %w(ruby ruby-dev libopenssl-ruby irb
                      build-essential wget ssl-cert)
        ui.msg "Updating apt caches..."
        run_command("sudo apt-get update")
        ui.msg "Installing required packages..."
        run_command("sudo DEBIAN_FRONTEND=noninteractive apt-get --yes install #{packages.join(' ')}")
        gem_install
      end

      def gem_install
        ui.msg "Installing rubygems from source..."
        release = "rubygems-1.7.2"
        file = "#{release}.tgz"
        url = "http://production.cf.rubygems.org/rubygems/#{file}"
        run_command("wget #{url}")
        run_command("tar zxf #{file}")
        run_command("cd #{release} && sudo ruby setup.rb --no-format-executable")
        run_command("sudo rm -rf #{release} #{file}")
        run_command("sudo gem install --no-rdoc --no-ri chef")
      end

      def issue
        run_command("cat /etc/issue")[:stdout]
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
          version = run_command("lsb_release -cs")[:stdout].strip
          {:type => "debian", :version => version}
        when %r{CentOS}
          {:type => "rpm", :version => "CentOS"}
        when %r{Red Hat Enterprise Linux}
          {:type => "rpm", :version => "Red Hat"}
        when %r{Scientific Linux SL}
          {:type => "rpm", :version => "Scientific Linux"}
        when %r{This is \\n\.\\O (\\s \\m \\r) \\t}
          {:type => "gentoo", :version => "Gentoo"}
        else
          raise "Contents of /etc/issue not recognized, please fork https://github.com/matschaffer/knife-solo and add support for your distro."
        end
      end
    end
  end
end
