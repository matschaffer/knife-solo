require 'knife-solo/tools'
require 'tempfile'

module KnifeSolo
  class Berkshelf
    def self.load_gem
      begin
        require 'berkshelf'
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

    # Installs Berkshelf if Berksfile is found and berkshelf gem installed
    # Returns the cookbook path or nil
    def install
      if !File.exist? 'Berksfile'
        Chef::Log.debug "Berksfile not found"
        nil
      elsif !Berkshelf.load_gem
        ui.warn "Berkshelf could not be loaded"
        ui.warn "Please add the berkshelf gem to your Gemfile or install it manually with `gem install berkshelf`"
        nil
      else
        path = berkshelf_path
        if path == :tmpdir
          path = @berks_tmp_dir = Dir.mktmpdir('berks-')
        end
        ui.msg "Installing Berkshelf cookbooks to '#{path}'..."
        ::Berkshelf::Berksfile.from_file('Berksfile').install(:path => path)
        path
      end
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
  end
end
