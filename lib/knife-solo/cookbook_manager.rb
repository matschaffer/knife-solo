require 'chef/mixin/convert_to_class_name'
require 'knife-solo/gitignore'
require 'knife-solo/tools'

module KnifeSolo
  module CookbookManager
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      include Chef::Mixin::ConvertToClassName

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
          true
        rescue LoadError
          false
        end
      end

      # Key in Chef::Config and CLI options
      def config_key
        snake_case_basename(name).to_sym
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

      def to_s
        name
      end

      def name
        self.class.name.split('::').last
      end

      def gem_name
        self.class.gem_name
      end

      def gem_installed?
        self.class.load_gem
      end

      def conf_file(base = nil)
        base ? File.join(base, self.class.conf_file_name) : self.class.conf_file_name
      end

      def enabled_by_chef_config?
        KnifeSolo::Tools.config_value(config, self.class.config_key)
      end

      def conf_file_exists?(base = nil)
        File.exists?(conf_file(base))
      end

      # Runs the manager and returns the path to the cookbook directory
      def install!
        raise "Must be overridden by the including class"
      end

      # Runs installer if the configuration file is found and gem installed
      # Returns the cookbook path or nil
      def install
        if !conf_file_exists?
          Chef::Log.debug "#{conf_file} not found"
        elsif !self.class.load_gem
          ui.warn "#{name} could not be loaded"
          ui.warn "Please add the #{gem_name} gem to your Gemfile or install it manually with `gem install #{gem_name}`"
        else
          return install!
        end
        nil
      end

      def bootstrap(base)
        ui.msg "Setting up #{name}..."
        unless conf_file_exists?(base)
          File.open(conf_file(base), 'w') { |f| f.puts(initial_config) }
        end
        if KnifeSolo::Tools.config_value(config, :git) && gitignores
          KnifeSolo::Gitignore.new(base).add(gitignores)
        end
      end

      # Returns content for configuration file when bootstrapping
      def initial_config
        raise "Must be overridden by the including class"
      end

      # Returns an array of strings to gitignore when bootstrapping
      def gitignores
        nil
      end
    end
  end
end
