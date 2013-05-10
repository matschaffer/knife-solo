require 'knife-solo/tools'

module KnifeSolo
  class Librarian
    def self.load_gem
      begin
        require 'librarian/action'
        require 'librarian/chef'
      rescue LoadError
        false
      else
        true
      end
    end

    attr_reader :config, :ui

    def initialize(config, ui)
      @config = config
      @ui = ui
    end

    # Installs Librarian if Cheffile is found and librarian-chef gem installed
    # Returns the cookbook path or nil
    def install
      if !File.exist? 'Cheffile'
        Chef::Log.debug "Cheffile not found"
        nil
      elsif !Librarian.load_gem
        ui.warn "Librarian-Chef could not be loaded"
        ui.warn "Please add the librarian-chef gem to your Gemfile or install it manually with `gem install librarian-chef`"
        nil
      else
        ui.msg "Installing Librarian cookbooks..."
        ::Librarian::Action::Resolve.new(env).run
        ::Librarian::Action::Install.new(env).run
        env.install_path
      end
    end

    def env
      @env ||= ::Librarian::Chef::Environment.new
    end
  end
end
