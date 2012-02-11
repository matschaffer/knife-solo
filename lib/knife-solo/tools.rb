module KnifeSolo
  module Tools
    def system!(command)
      raise "Failed to launch command #{command}" unless system(command)
    end
  end
end