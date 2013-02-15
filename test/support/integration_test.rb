require 'json'
require 'net/http'

require 'support/test_case'

case_pattern = $base_dir.join('integration', 'cases', '*.rb')
Dir[case_pattern].each do |use_case|
  require use_case
end

# Base class for EC2 integration tests
class IntegrationTest < TestCase
  include Loggable

  # Returns a name for the current test's server
  # that should be fairly unique.
  def server_name
    "knife-solo_#{self.class}"
  end

  # Shortcut to access the test runner
  def runner
    MiniTest::Unit.runner
  end

  # Returns the server for this test, retrieved from the test runner
  def server
    return @server if @server
    @server = runner.get_server(self)
  end

  # The flavor to run this test on
  def flavor_id
    "m1.small"
  end

  # Sets up a kitchen directory to work in
  def setup
    @kitchen = $base_dir.join('support', 'kitchens', self.class.to_s)
    FileUtils.remove_entry_secure(@kitchen, true)
    @kitchen.dirname.mkpath
    system "knife solo init #{@kitchen} >> #{log_file}"
    @start_dir = Dir.pwd
    Dir.chdir(@kitchen)
    prepare_server
  end

  # Gets back to the start dir
  def teardown
    Dir.chdir(@start_dir)
  end

  # Writes out the given node hash as a json file
  def write_nodefile(node)
    write_json_file("nodes/#{server.public_ip_address}.json", node)
  end

  # Writes out an object to the given file as JSON
  def write_json_file(file, data)
    FileUtils.mkpath(File.dirname(file))
    File.open(file, 'w') do |f|
      f.print data.to_json
    end
  end

  # Prepares the server unless it has already been marked as such
  def prepare_server
    return if server.tags["knife_solo_prepared"]
    assert_subcommand prepare_command
    runner.tag_as_prepared(server)
  end

  # The prepare command to use on this server
  def prepare_command
    "prepare #{omnibus_options}"
  end

  def omnibus_options
    return "" if ENV['CHEF_VERSION'].to_s.empty?

    v = `knife --version`.split(':')
    v[0].strip == 'Chef' ? "--bootstrap-version=#{v[1].strip}" : ''
  end

  # Provides the path to the runner's key file
  def key_file
    runner.key_file
  end

  # The ssh-style connection string used to connect to the current node
  def connection_string
    "-i #{key_file} #{user}@#{server.public_ip_address}"
  end

  # Asserts that a prepare or cook command is successful
  def assert_subcommand(subcommand)
    system "knife solo #{subcommand} #{connection_string} -VV >> #{log_file}"
    assert $?.success?
  end
end

