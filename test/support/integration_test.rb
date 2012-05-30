require 'json'
require 'net/http'

require 'support/test_case'

# Base class for EC2 integration tests
class IntegrationTest < TestCase
  include Loggable

  # Returns a name for the current test's server
  # that should be fairly unique.
  def server_name
    "knife_solo-#{image_id}"
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
    @kitchen.dirname.mkpath
    system "knife kitchen #{@kitchen} >> #{log_file}"
    @start_dir = Dir.pwd
    Dir.chdir(@kitchen)
    prepare_server
  end

  # Removes the test kitchen
  def teardown
    Dir.chdir(@start_dir)
    FileUtils.remove_entry_secure(@kitchen)
  end

  # Writes out the given node hash as a json file
  def write_nodefile(node)
    File.open("nodes/#{server.public_ip_address}.json", 'w') do |f|
      f.print node.to_json
    end
  end

  # Prepares the server unless it has already been marked as such
  def prepare_server
    return if server.tags["knife_solo_prepared"]
    assert_subcommand "prepare"
    runner.tag_as_prepared(server)
  end

  # Asserts that a prepare or cook command is successful
  def assert_subcommand(subcommand)
    key_file = MiniTest::Unit.runner.key_file
    system "knife #{subcommand} -i #{key_file} #{user}@#{server.public_ip_address} -VV >> #{log_file}"
    assert $?.success?
  end

  # Tries to run cook on the box
  module EmptyCook
    def test_empty_cook
      write_nodefile(run_list: [])
      assert_subcommand "cook"
    end
  end

  # Tries to cook with apache2 cookbook and
  # verifies the "It Works!" page is present.
  module Apache2Cook
    def write_cheffile
      File.open('Cheffile', 'w') do |f|
        f.print <<-CHEF
            site 'http://community.opscode.com/api/v1'
            cookbook 'apache2'
        CHEF
      end
    end

    def http_response
      Net::HTTP.get(URI.parse("http://"+server.public_ip_address))
    end

    def default_apache_message
      /It works!/
    end

    def test_apache2
      write_cheffile
      system "librarian-chef install >> #{log_file}"
      write_nodefile(run_list: ["recipe[apache2]"])
      assert_subcommand "cook"
      assert_match default_apache_message, http_response
    end
  end
end

