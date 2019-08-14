module KnifeSolo::Bootstraps
  class Darwin < Base

    def issue
      @issue ||= run_command("sw_vers -productVersion").stdout.strip
    end

    def distro
      case issue
      when %r{10.(?:[6-9]|1[0-2])}
        {:type => 'omnibus'}
      else
        raise "OS X version #{issue} not supported"
      end
    end

    def bootstrap!
      super
      if issue.split('.')[1].to_i >= 11
        # El Capitan and beyond do not have /usr/local/bin in the default paths,
        # which is where chef gets installed.
        path = "/usr/local/bin"
        path_command = "[[ $PATH == *#{path}* ]] || echo 'export PATH=#{path}:$PATH' >> ~/.bashrc"
        run_command(path_command)
      end
    end
  end
end
