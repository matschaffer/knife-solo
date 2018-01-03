module KnifeSolo
  def self.version
    '0.7.0.pre3'
  end

  def self.post_install_message
    <<-TXT.gsub(/^ {6}/, '').strip
      Thanks for installing knife-solo!

      If you run into any issues please let us know at:
        https://github.com/matschaffer/knife-solo/issues

      If you are upgrading knife-solo please uninstall any old versions by
      running `gem clean knife-solo` to avoid any errors.

      See http://bit.ly/CHEF-3255 for more information on the knife bug
      that causes this.
    TXT
  end

  def self.prerelease?
    Gem::Version.new(self.version).prerelease?
  end
end
