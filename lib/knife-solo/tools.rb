module KnifeSolo
  module Tools
    class CommandFailedError < StandardError
    end

    def system!(command)
      raise CommandFailedError.new("Failed to launch command #{command}") unless system(command)
    end
  end
end