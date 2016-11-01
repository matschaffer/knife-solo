module KnifeSolo::Bootstraps
  class Darwin < Base

    def issue
      @issue ||= run_command("sw_vers -productVersion").stdout.strip
    end

    def distro
      if Gem::Requirement.new('>=10.6').satisfied_by? Gem::Version.new(issue)
        {:type => 'omnibus'}
      else
        raise "OS X version #{issue} not supported"
      end
    end
  end
end
