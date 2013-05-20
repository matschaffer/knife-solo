module KnifeSolo
  module CookbookManager
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      # Returns an Array of libraries to load
      def gem_libraries
        raise "Must be overridden by the including class"
      end

      def gem_name
        gem_libraries.first
      end

      def load_gem
        begin
          gem_libraries.each { |lib| require lib }
        rescue LoadError
          false
        else
          true
        end
      end

      def gem_installed?
        load_gem
      end

      # Returns the base name of the configuration file
      def conf_file_name
        raise "Must be overridden by the including class"
      end
    end

    module InstanceMethods
      attr_reader :config, :ui

      def initialize(config, ui)
        @config = config
        @ui = ui
      end

      def name
        self.class.name.split('::').last
      end

      def gem_name
        self.class.gem_name
      end

      def conf_file(base = nil)
        base ? File.join(base, self.class.conf_file_name) : self.class.conf_file_name
      end

      # Runs the manager and returns the path to the cookbook directory
      def install!
        raise "Must be overridden by the including class"
      end

      # Runs installer if the configuration file is found and gem installed
      # Returns the cookbook path or nil
      def install
        if !File.exists?(conf_file)
          Chef::Log.debug "#{conf_file} not found"
          nil
        elsif !self.class.load_gem
          ui.warn "#{name} could not be loaded"
          ui.warn "Please add the #{gem_name} gem to your Gemfile or install it manually with `gem install #{gem_name}`"
          nil
        else
          install!
        end
      end
    end
  end
end
