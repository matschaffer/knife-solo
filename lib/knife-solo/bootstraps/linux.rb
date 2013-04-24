module KnifeSolo::Bootstraps
  class Linux < Base
    def issue
      prepare.run_command("cat /etc/redhat-release").stdout.strip || 
      prepare.run_command("cat /etc/issue").stdout.strip || 
      prepare.run_command("lsb_release -d -s").stdout.strip
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

    def debianoid_gem_install
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

    def debianoid_omnibus_install
      run_command("sudo apt-get update")
      run_command("sudo apt-get -y install rsync ca-certificates")
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
      when %r{Debian GNU/Linux 6}
        {:type => (x86? ? "debianoid_omnibus" : "debianoid_gem")}
      when %r{Debian}
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
      when %r{Fedora release}
        {:type => "yum_omnibus"}
      when %r{Scientific Linux}
        {:type => "yum_omnibus"}
      when %r{SUSE Linux Enterprise Server 1[12]}
        {:type => "omnibus"}
      when %r{openSUSE 12}
        {:type => "zypper_omnibus"}
      when %r{This is \\n\.\\O \(\\s \\m \\r\) \\t}
        {:type => "emerge_gem"}
      else
        raise "Distro not recognized from looking at /etc/issue. Please fork https://github.com/matschaffer/knife-solo and add support for your distro."
      end
      Chef::Log.debug("Distro detection yielded: #{@distro}")
      @distro
    end #issue

  end
end
