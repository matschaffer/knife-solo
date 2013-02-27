module KnifeSolo::Bootstraps
  class Linux < Base

    def issue
      prepare.run_command("cat /etc/issue").stdout.strip || prepare.run_command("lsb_release -d -s").stdout.strip
    end

    def x86?
      machine = run_command('uname -m').stdout.strip
      %w{i686 x86 x86_64}.include?(machine)
    end

    def lsb_release_codename
      run_command("lsb_release -cs").stdout.strip
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

    def distro
      return @distro if @distro
      @distro = case issue
      when %r{Debian GNU/Linux 6}
        {:type => (x86? ? "debianoid_omnibus" : "debian_gem"), :version => "squeeze"}
      when %r{Debian}
        {:type => "debian_gem", :version => lsb_release_codename}
      when %r{Ubuntu}i
        {:type => (x86? ? "debianoid_omnibus" : "debian_gem"), :version => lsb_release_codename}
      when %r{Linaro}
        {:type => "debian_gem", :version => lsb_release_codename}
      when %r{CentOS.*? 5}
        {:type => "yum_omnibus", :version => "RHEL5"}
      when %r{CentOS.*? 6}
        {:type => "yum_omnibus", :version => "RHEL6"}
      when %r{Amazon Linux}
        {:type => "yum_omnibus", :version => "RHEL6"}
      when %r{Red Hat Enterprise.*? 5}
        {:type => "yum_omnibus", :version => "RHEL5"}
      when %r{Red Hat Enterprise.*? 6}
        {:type => "yum_omnibus", :version => "RHEL6"}
      when %r{Fedora release.*? 15}
        {:type => "yum_omnibus", :version => "FC15"}
      when %r{Fedora release.*? 16}
        {:type => "yum_omnibus", :version => "FC16"}
      when %r{Fedora release.*? 17}
        {:type => "yum_omnibus", :version => "FC17"}
      when %r{Scientific Linux.*? 5}
        {:type => "yum_omnibus", :version => "RHEL5"}
      when %r{Scientific Linux.*? 6}
        {:type => "yum_omnibus", :version => "RHEL6"}
      when %r{SUSE Linux Enterprise Server 1[12]}
        {:type => "omnibus", :version => "SLES11"}
      when %r{openSUSE 1[12]}
        {:type => "omnibus", :version => "openSUSE"}
      when %r{This is \\n\.\\O \(\\s \\m \\r\) \\t}
        {:type => "emerge_gem", :version => "Gentoo"}
      else
        raise "Distro not recognized from looking at /etc/issue. Please fork https://github.com/matschaffer/knife-solo and add support for your distro."
      end
      Chef::Log.debug("Distro detection yielded: #{@distro}")
      @distro
    end #issue

  end
end
