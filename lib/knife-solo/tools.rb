module KnifeSolo
  module Tools
    def system!(*command)
      raise "Failed to launch command #{command}" unless system(*command)
    end

    def windows_client?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    end

    def config_value(key, default = nil)
      Tools.config_value(config, key, default)
    end

    # Chef 10 compatible way of getting correct precedence for command line
    # and configuration file options. Adds correct handling of `false` values
    # to the original example in
    # http://docs.opscode.com/breaking_changes_chef_11.html#knife-configuration-parameter-changes
    def self.config_value(config, key, default = nil)
      key = key.to_sym
      if !config[key].nil?
        config[key]
      elsif !Chef::Config[:knife][key].nil?
        # when Chef 10 support is dropped, this branch can be removed
        # as Chef 11 automatically merges the values to the `config` hash
        Chef::Config[:knife][key]
      else
        default
      end
    end

  end
end
