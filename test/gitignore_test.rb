require 'test_helper'
require 'support/kitchen_helper'

require 'knife-solo/gitignore'

class GitignoreTest < TestCase
  include KitchenHelper

  def test_creates_with_one_entry
    outside_kitchen do
      KnifeSolo::Gitignore.new('.').add("foo")
      assert_equal "foo\n", IO.read('.gitignore')
    end
  end

  def test_creates_with_multiple_entries
    outside_kitchen do
      KnifeSolo::Gitignore.new('.').add("foo", "/bar")
      assert_equal "foo\n/bar\n", IO.read('.gitignore')
    end
  end

  def test_creates_with_array
    outside_kitchen do
      KnifeSolo::Gitignore.new('.').add(%w[foo/ bar])
      assert_equal "foo/\nbar\n", IO.read('.gitignore')
    end
  end

  def test_appends_new_entries
    outside_kitchen do
      File.open(".gitignore", "w") do |f|
        f.puts "foo"
      end
      KnifeSolo::Gitignore.new('.').add(["bar.*"])
      assert_equal "foo\nbar.*\n", IO.read('.gitignore')
    end
  end

  def test_appends_only_new_entries
    outside_kitchen do
      File.open(".gitignore", "w") do |f|
        f.puts "*.foo"
      end
      KnifeSolo::Gitignore.new('.').add("!foo", "*.foo")
      assert_equal "*.foo\n!foo\n", IO.read('.gitignore')
    end
  end

  def test_appends_only_if_any_new_entries
    outside_kitchen do
      File.open(".gitignore", "w") do |f|
        f.puts "!foo"
        f.puts "/bar/*.baz"
      end
      KnifeSolo::Gitignore.new('.').add(["!foo", "/bar/*.baz"])
      assert_equal "!foo\n/bar/*.baz\n", IO.read('.gitignore')
    end
  end
end
