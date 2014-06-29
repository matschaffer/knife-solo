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
      if defined?(::Berkshelf) && Gem::Version.new(::Berkshelf::VERSION) >= Gem::Version.new("3.0.0")
        'source "https://api.berkshelf.com"'
      else
        'site :opscode'
      end
    end
  end
end
