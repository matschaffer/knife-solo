require 'knife-solo/cookbook_manager'

module KnifeSolo
  class Librarian
    include CookbookManager

    def self.gem_libraries
      %w[librarian/action librarian/chef]
    end

    def self.conf_file_name
      'Cheffile'
    end

    def self.gem_name
      'librarian-chef'
    end

    def install!
      ui.msg "Installing Librarian cookbooks..."
      ::Librarian::Action::Resolve.new(env).run
      ::Librarian::Action::Install.new(env).run
      env.install_path
    end

    def env
      @env ||= ::Librarian::Chef::Environment.new
    end

    def initial_config
      "site 'http://community.opscode.com/api/v1'"
    end

    # Returns an array of strings to gitignore when bootstrapping
    def gitignores
      %w[/tmp/librarian/]
    end
  end
end
