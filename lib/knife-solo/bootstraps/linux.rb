module KnifeSolo::Bootstraps
  class Linux < Base

    def issue
      prepare.run_command("cat /etc/issue").stdout.strip
    end

    def package_list
      @packages.join(' ')
    end

    def gem_packages
      ['ruby-shadow','chef']
    end

    def http_client_get_url(url)
      "wget #{url}"
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
      repo_url = "http://rbel.co/"
      if distro[:version] == "RHEL5"
        repo_path = "/rbel5"
      else
        repo_path = "/rbel6"
      end
      installed = "is already installed"
      result = run_command("sudo rpm -Uvh #{repo_url}#{repo_path}")
      raise result.stderr_or_stdout unless result.success? || result.stdout.match(installed)
    end

    def yum_install
      ui.msg("Installing required packages...")
      add_yum_repos
      @packages = %w(rubygem-chef rsync)
      run_command("sudo yum -y install #{package_list}")
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
      when %r{Debian GNU/Linux 5}
        {:type => "debian_gem", :version => "lenny"}
      when %r{Debian GNU/Linux 6}
        {:type => "debian_gem", :version => "squeeze"}
      when %r{Debian GNU/Linux wheezy}
        {:type => "debian_gem", :version => "wheezy"}
      when %r{Ubuntu}
        version = run_command("lsb_release -cs").stdout.strip
        {:type => "debian_gem", :version => version}
      when %r{CentOS.*? 5}
        {:type => "yum", :version => "RHEL5"}
      when %r{CentOS.*? 6}
        {:type => "yum", :version => "RHEL6"}
      when %r{Red Hat Enterprise.*? 5}
        {:type => "yum", :version => "RHEL5"}
      when %r{Red Hat Enterprise.*? 6}
        {:type => "yum", :version => "RHEL6"}
      when %r{Scientific Linux.*? 5}
        {:type => "yum", :version => "RHEL5"}
      when %r{Scientific Linux.*? 6}
        {:type => "yum", :version => "RHEL6"}
      when %r{SUSE Linux Enterprise Server 11 SP1}
        {:type => "zypper_gem", :version => "SLES11"}
      when %r{openSUSE 11.4}
        {:type => "zypper_gem", :version => "openSUSE"}
      when %r{This is \\n\.\\O (\\s \\m \\r) \\t}
        {:type => "gentoo_gem", :version => "Gentoo"}
      else
        raise "Distro not recognized from looking at /etc/issue. Please fork https://github.com/matschaffer/knife-solo and add support for your distro."
      end
      Chef::Log.debug("Distro detection yielded: #{@distro}")
      @distro
    end #issue

  end
end
