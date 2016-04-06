require 'knife-solo/berkshelf'
require 'knife-solo/librarian'

module KnifeSolo
  class CookbookManagerSelector
    attr_reader :config, :ui

    def initialize(config, ui)
      @config = config
      @ui = ui
    end

    def select(base)
      Chef::Log.debug "Selecting cookbook manager..."

      if (selected = select_or_disable_by_chef_config!)
        return selected
      elsif managers.empty?
        Chef::Log.debug "All disabled by configuration"
        return nil
      end

      selected = select_by_existing_conf_file(base) || select_by_installed_gem
      if selected.nil?
        Chef::Log.debug "Nothing selected"
        # TODO: ui.msg "Recommended to use a cookbook manager"
      end
      selected
    end

    private

    def managers
      @managers ||= [
        KnifeSolo::Berkshelf.new(config, ui),
        KnifeSolo::Librarian.new(config, ui)
      ]
    end

    def select_or_disable_by_chef_config!
      @managers = managers.select do |manager|
        if (conf = manager.enabled_by_chef_config?)
          Chef::Log.debug "#{manager} selected by configuration"
          return manager
        elsif conf == false
          Chef::Log.debug "#{manager} disabled by configuration"
          false
        else # conf == nil
          true
        end
      end
      nil
    end

    def select_by_existing_conf_file(base)
      managers.each do |manager|
        if defined?(@base) && manager.conf_file_exists?(@base)
          Chef::Log.debug "#{manager} selected because of existing #{manager.conf_file}"
          return manager
        end
      end
      nil
    end

    def select_by_installed_gem
      managers.each do |manager|
        if manager.gem_installed?
          Chef::Log.debug "#{manager} selected because of installed gem"
          return manager
        end
      end
      nil
    end
  end
end
