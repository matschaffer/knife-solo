module KnifeSolo
  def self.version
    '0.2.0.pre2'
  end

  def self.prerelease?
    Gem::Version.new(self.version).prerelease?
  end
end
