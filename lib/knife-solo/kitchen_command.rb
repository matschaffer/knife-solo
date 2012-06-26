require 'knife-solo/knife_solo_error'

module KnifeSolo
  module KitchenCommand
    class OutOfKitchenError < KnifeSoloError
      def message
        "This command must be run inside a Chef solo kitchen."
      end
    end

    def self.required_directories
      %w(nodes roles cookbooks data_bags site-cookbooks)
    end

    def self.required_files
      %w(solo.rb)
    end

    def self.all_requirements
      required_files + required_directories
    end

    def run
      raise OutOfKitchenError.new unless required_files_present?
    end

    def required_files_present?
      KitchenCommand.all_requirements.inject(true) do |m, f|
        check = File.exists?(f)
        Chef::Log.warn "#{f} is a required file/directory" unless check
        m && check
      end
    end
  end
end
