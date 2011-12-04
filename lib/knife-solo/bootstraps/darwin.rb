module KnifeSolo::Bootstraps
  class Darwin < Base

    def issue
      run_command("sw_vers -productVersion").stdout.strip
    end

    def gem_packages
      ['chef']
    end
    
    def distro
      case issue
      when %r{10.5}
          {:type => 'gem', :version => 'leopard'}
      when %r{10.6}
          {:type => 'gem', :version => 'snow_leopard'}
      else
          raise "OSX version #{issue} not supported"
      end
    end

    def has_xcode_installed?
      result = run_command("xcodebuild -version")
      result.success?
    end

    def http_client_get_url(url)
      filename = url.split("/").last
      "curl '#{url}' >> #{filename}"
    end

    def run_pre_bootstrap_checks
      raise 'xcode not installed, which is required to do anything.  please install and run again.' unless has_xcode_installed?
    end

  end
end
