module KnifeSolo
  module Tools
    def system!(command)
      raise "Failed to launch command #{command}" unless system(command)
    end

    def windows_client?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    end

    def quiet_system(command)
      system "#{command} #{windows_client? ? '>NUL' : '>/dev/null'} 2>&1"
    end
  end
end
