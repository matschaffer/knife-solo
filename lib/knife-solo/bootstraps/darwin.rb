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
  end
end
