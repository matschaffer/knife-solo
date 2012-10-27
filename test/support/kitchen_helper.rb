require 'tmpdir'

require 'chef/knife/kitchen'

module KitchenHelper
  SYNTAX_ERROR_FILE = "syntax_error.rb"

  def in_kitchen
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        knife_command(Chef::Knife::Kitchen, ".").run
        yield
      end
    end
  end

  def outside_kitchen
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield
      end
    end
  end

  def create_syntax_error_file
    File.open(SYNTAX_ERROR_FILE, 'w') do |f|
      f << "this is a blatant ruby syntax error."
    end
    assert !check_syntax(SYNTAX_ERROR_FILE)
  end

  def ignore_syntax_error_file
    File.open("chefignore", 'w') do |f|
      f << SYNTAX_ERROR_FILE
    end
  end

  def check_syntax(file)
    `ruby -c #{file} >/dev/null 2>&1 && echo 'true'`.strip == 'true'
  end
end
