require 'knife-solo/knife_solo_error'

module KnifeSolo
  module KitchenCommand
    class OutOfKitchenError < KnifeSoloError
      def message
        "This command must be run inside a Chef solo kitchen."
      end
    end

    def self.required_files
      %w(solo.rb)
    end

    def run
      raise OutOfKitchenError.new unless required_files_present?
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

    def first_cli_arg_is_a_hostname?
      @name_args.first =~ /\A([^@]+(?>@)[^@]+|[^@]+?(?!@))\z/
    end

    def validate_first_cli_arg_is_a_hostname!(error_class)
      unless first_cli_arg_is_a_hostname?
        ui.msg opt_parser.help
        raise error_class.new "need to pass atleast a [user@]hostname as the first argument"
      end
    end

  end
end
