module KnifeSolo
  module KitchenCommand
    class OutOfKitchenError < StandardError
      def message
        "This command must be run inside a Chef solo kitchen."
      end
    end

    def required_files
      %w(nodes roles cookbooks data_bags solo.rb)
    end

    def run
      raise OutOfKitchenError.new unless required_files_present?
    end

    def required_files_present?
      required_files.inject(true) { |m, f| m && File.exists?(f) }
    end
  end
end
