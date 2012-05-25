class TestCase < MiniTest::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end
end
