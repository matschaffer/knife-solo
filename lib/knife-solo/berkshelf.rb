require 'digest/sha1'
require 'fileutils'
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

      berksfile = ::Berkshelf::Berksfile.from_file('Berksfile')
      if berksfile.respond_to?(:vendor)
        FileUtils.rm_rf(path)
        berksfile.vendor(path)
      else
        berksfile.install(:path => path)
      end

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
      "source 'https://api.berkshelf.com'"
    end
  end
end
