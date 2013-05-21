require 'digest/sha1'
require 'knife-solo/cookbook_manager'
require 'knife-solo/tools'

module KnifeSolo
  class Berkshelf
    include CookbookManager

    def self.gem_libraries
      %w[berkshelf]
    end

    def self.conf_file_name
      'Berksfile'
    end

    def install!
      path = berkshelf_path
      ui.msg "Installing Berkshelf cookbooks to '#{path}'..."
      ::Berkshelf::Berksfile.from_file('Berksfile').install(:path => path)
      path
    end

    def berkshelf_path
      KnifeSolo::Tools.config_value(config, :berkshelf_path) || default_path
    end

    def default_path
      File.join(::Berkshelf.berkshelf_path, 'knife-solo',
        Digest::SHA1.hexdigest(File.expand_path('.')))
    end

    def initial_config
      'site :opscode'
    end
  end
end
