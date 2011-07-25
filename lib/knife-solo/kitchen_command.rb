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
      all_present  = required_files.inject(true) { |m, f| m && File.exists?(f) }
      raise OutOfKitchenError.new unless all_present
    end
  end
end
