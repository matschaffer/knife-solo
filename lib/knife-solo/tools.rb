module KnifeSolo
  module Tools
    def system!(command)
      raise "Failed to launch command #{command}" unless system(command)
    end

    def windows_client?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    end

    def quiet_system(command)
      redirect_output = '>/dev/null 2>&1'
      redirect_output = '>NUL 2>&1' if windows_client?
      system "#{command} #{redirect_output}"
    end
  end
end
