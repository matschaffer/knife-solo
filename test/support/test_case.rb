class TestCase < MiniTest::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end

  def suppress_knife_error_output
    old_level = Chef::Log.level
    Chef::Log.level = :error
    yield
  ensure
    Chef::Log.level = old_level
  end
end
