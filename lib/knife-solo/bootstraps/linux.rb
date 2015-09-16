module KnifeSolo::Bootstraps
  class Linux < Base
    def issue
      commands = [
        'lsb_release -d -s',
        'cat /etc/redhat-release',
        'cat /etc/os-release',
        'cat /etc/issue'
      ]
      result = prepare.run_with_fallbacks(commands)
      result.success? ? result.stdout.strip : nil
    end

    def x86?
      machine = run_command('uname -m').stdout.strip
      %w{i686 x86 x86_64}.include?(machine)
    end

    def package_list
      @packages.join(' ')
    end

    def gem_packages
      ['ruby-shadow']
    end

    def emerge_gem_install
      ui.msg("Installing required packages...")
      run_command("sudo USE='-test' ACCEPT_KEYWORDS='~amd64' emerge -u chef")
      gem_install
    end

    def pacman_install
      ui.msg("Installing required packages...")
      run_command("sudo pacman -Sy ruby rsync make gcc --noconfirm")
      run_command("sudo gem install chef --no-user-install --no-rdoc --no-ri")
    end

    def debianoid_gem_install
      ui.msg "Updating apt caches..."
      run_command("sudo apt-get update")

      ui.msg "Installing required packages..."
      @packages = %w(ruby ruby-dev libruby irb
                     build-essential wget ssl-cert rsync)
      result = run_command <<-BASH
        sudo DEBIAN_FRONTEND=noninteractive apt-get --yes install #{package_list}
      BASH

      if result.exit_code != 0
        ui.fatal "Failed to install packages. Try installing them manually: #{@packages.join(' ')}"
        exit 1
      end

      gem_install
    end

    def debianoid_omnibus_install
      run_command("sudo apt-get update")
      run_command("sudo apt-get -y install rsync ca-certificates wget")
      omnibus_install
    end

    def zypper_omnibus_install
      run_command("sudo zypper --non-interactive install rsync")
      omnibus_install
    end

    def yum_omnibus_install
      run_command("sudo yum clean all")
      run_command("sudo yum -y install rsync")
      omnibus_install
    end

    def distro
      return @distro if @distro
      @distro = case issue
      when %r{Debian GNU/Linux [678]}
        {:type => (x86? ? "debianoid_omnibus" : "debianoid_gem")}
      when %r{Debian}
        {:type => "debianoid_gem"}
      when %r{Raspbian}
        {:type => "debianoid_gem"}
      when %r{Linux Mint}
        {:type => "debianoid_gem"}
      when %r{Ubuntu}i
        {:type => (x86? ? "debianoid_omnibus" : "debianoid_gem")}
      when %r{Linaro}
        {:type => "debianoid_gem"}
      when %r{CentOS}
        {:type => "yum_omnibus"}
      when %r{Amazon Linux}
        {:type => "yum_omnibus"}
      when %r{Red Hat Enterprise}
        {:type => "yum_omnibus"}
      when %r{Oracle Linux Server}
        {:type => "yum_omnibus"}
      when %r{Enterprise Linux Enterprise Linux Server}
        {:type => "yum_omnibus"}
      when %r{Fedora release}
        {:type => "yum_omnibus"}
      when %r{Scientific Linux}
        {:type => "yum_omnibus"}
      when %r{CloudLinux}
        {:type => "yum_omnibus"}
      when %r{SUSE Linux Enterprise Server 1[12]}
        {:type => "omnibus"}
      when %r{openSUSE 1[23]}
        {:type => "zypper_omnibus"}
      when %r{This is \\n\.\\O \(\\s \\m \\r\) \\t}
        {:type => "emerge_gem"}
      when %r{Arch Linux}, %r{Manjaro Linux}
        {:type => "pacman"}
      else
        raise "Distribution not recognized. Please run again with `-VV` option and file an issue: https://github.com/matschaffer/knife-solo/issues"
      end
      Chef::Log.debug("Distro detection yielded: #{@distro}")
      @distro
    end #issue

  end
end
