require 'test_helper'

require 'chef/knife/kitchen'

class KitchenTest < TestCase
  def test_produces_folders
    Dir.chdir("/tmp") do
      command("testkitchen").run
      assert File.exist?("testkitchen/nodes")
    end
  end

  def test_produces_gitkeep_in_folders
    Dir.chdir("/tmp") do
      command("testkitchen").run
      assert File.exist?("testkitchen/nodes/.gitkeep")
    end
  end

  def teardown
    FileUtils.rm_r("/tmp/testkitchen")
  end

  def command(*args)
    Chef::Knife::Kitchen.load_deps
    Chef::Knife::Kitchen.new(args)
  end
end
