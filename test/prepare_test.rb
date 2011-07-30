require 'test_helper'

require 'chef/knife/prepare'

class PrepareTest < TestCase
  def test_generates_a_node_config
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")

      cmd = command("somehost")
      cmd.generate_node_config

      assert cmd.node_config.exist?
    end
  end

  def test_wont_overwrite_node_config
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")

      cmd = command("somehost")

      File.open(cmd.node_config, "w") do |f|
        f << "testdata"
      end

      cmd.generate_node_config

      assert_match "testdata", cmd.node_config.read
    end
  end

  def teardown
    FileUtils.rm_r("/tmp/nodes")
  end

  def command(*args)
    Chef::Knife::Prepare.load_deps
    Chef::Knife::Prepare.new(args)
  end
end
