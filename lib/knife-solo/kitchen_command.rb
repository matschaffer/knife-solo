module KnifeSolo
  module KitchenCommand
    def self.required_files
      %w(solo.rb)
    end

    def validate_kitchen!
      unless required_files_present?
        ui.fatal "This command must be run inside a Chef solo kitchen."
        exit 1
      end
    end

    def required_files_present?
      KitchenCommand.required_files.inject(true) do |m, f|
        check = File.exists?(f)
        warn_for_required_file(f) unless check
        m && check
      end
    end

    def warn_for_required_file(file)
      ui.error "#{file} is a required file/directory"
    end
  end
end
