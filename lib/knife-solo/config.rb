require 'chef/config'

module KnifeSolo
  # Encapsulates some logic for checking and extracting
  # path configuration from the structure of the
  # current kitchen
  class Config
    def solo_path
      Chef::Config.knife[:solo_path]
    end

    def chef_path
      solo_path || './chef-solo'
    end

    def cookbook_path
      if using_custom_solorb?
        Chef::Config.from_file('solo.rb')
        Array(Chef::Config.cookbook_path).first
      else
        chef_path + '/cookbooks'
      end
    end

    def patch_path
      cookbook_path + "/chef_solo_patches/libraries"
    end

    def using_custom_solorb?
      File.exist?('solo.rb')
    end

    def validate!
      raise Error, "You have a solo.rb file, but knife[:solo_path] is not set. You probably need to delete solo.rb unless you've customized it. See https://github.com/matschaffer/knife-solo/wiki/Upgrading-to-0.3.0 for more information." if using_custom_solorb? && solo_path.nil?
    end

    class Error < StandardError; end
  end
end
