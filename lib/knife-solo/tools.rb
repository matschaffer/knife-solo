module KnifeSolo
  module Tools
    def system!(command)
      raise "Failed to launch command #{command}" unless system(command)
    end

    def windows_client?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    end
  end
end
