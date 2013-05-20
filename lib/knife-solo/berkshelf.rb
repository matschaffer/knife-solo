require 'fileutils'
require 'knife-solo/cookbook_manager'
require 'knife-solo/tools'
require 'tempfile'

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
      if path == :tmpdir
        path = @berks_tmp_dir = Dir.mktmpdir('berks-')
      end
      ui.msg "Installing Berkshelf cookbooks to '#{path}'..."
      ::Berkshelf::Berksfile.from_file('Berksfile').install(:path => path)
      path
    end

    def cleanup
      FileUtils.remove_entry_secure(@berks_tmp_dir) if @berks_tmp_dir
    end

    def berkshelf_path
      path = KnifeSolo::Tools.config_value(config, :berkshelf_path)
      if path.nil?
        ui.warn "`knife[:berkshelf_path]` is not set. Using temporary directory to install Berkshelf cookbooks."
        path = :tmpdir
      end
      path
    end

    def initial_config
      "site :opscode"
    end
  end
end
