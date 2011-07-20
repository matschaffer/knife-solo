require 'test_helper'

class KitchenTest < TestCase
  def test_produces_folders
    Dir.chdir("/tmp") do
      system("knife", "kitchen", "testkitchen")
      assert File.exist?("testkitchen/nodes")
    end
  end

  def teardown
    FileUtils.rm_r("/tmp/testkitchen")
  end
end
