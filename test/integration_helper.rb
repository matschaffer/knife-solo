require 'test_helper'
require 'pathname'
require 'logger'
require 'yaml'
require 'net/http'

$base_dir = Pathname.new(__FILE__).dirname

MiniTest::Parallel.processor_count = 5

# A module that provides logger and log_file attached to an integration log file
module Loggable
  # The file that logs will go do, using the class name as a differentiator
  def log_file
    return @log_file if @log_file
    @log_file = $base_dir.join('..', 'log', "#{self.class}-integration.log")
    @log_file.dirname.mkpath
    @log_file
  end

  # The logger object so you can say logger.info to log messages
  def logger
    @logger ||= Logger.new(log_file)
  end
end

class IntegrationTest < TestCase
  include Loggable

  # Returns a name for the current test's server
  # that should be fairly unique.
  def server_name
    "knife_solo-#{image_id}"
  end

  # Returns the server for this test, retrieved from the test runner
  def server
    return @server if @server
    @server = MiniTest::Unit.runner.get_server(self)
  end

  # The flavor to run this test on
  def flavor_id
    "m1.small"
  end

  # Tries to run prepare and cook on the box
  module BasicPrepareAndCook
    def setup
      @kitchen = $base_dir.join('support', 'kitchens', self.class.to_s)
      @kitchen.dirname.mkpath
      system "knife kitchen #{@kitchen} >> #{log_file}"
    end

    def teardown
      FileUtils.remove_entry_secure(@kitchen)
      super
    end

    def assert_subcommand(subcommand)
      verbose = ENV['VERBOSE'] && "-VV"
      key_file = MiniTest::Unit.runner.key_file
      system "knife #{subcommand} -i #{key_file} #{user}@#{server.public_ip_address} #{verbose} >> #{log_file}"
      assert $?.success?
    end

    def test_prepare_and_cook
      Dir.chdir(@kitchen) do
        assert server.public_ip_address
        # assert_subcommand "prepare"
        # assert_subcommand "cook"
      end
    end
  end

  module CookApache2
    include BasicPrepareAndCook

    def write_cheffile
      File.open('Cheffile', 'w') do |f|
        f.print <<-CHEF
            site 'http://community.opscode.com/api/v1'
            cookbook 'apache2'
        CHEF
      end
    end

    def write_nodefile
      File.open("nodes/#{server.public_ip_address}.json", 'w') do |f|
        f.print <<-JSON
          { "run_list": ["recipe[apache2]"] }
        JSON
      end
    end

    def http_response
      Net::HTTP.get(URI.parse("http://"+server.public_ip_address))
    end

    def test_apache2
      Dir.chdir(@kitchen) do
        write_cheffile
        system "librarian-chef install >> #{log_file}"
        assert_subcommand "prepare"
        write_nodefile
        assert_subcommand "cook"
        assert_match /It works!/, http_response
      end
    end
  end
end

# A custom runner that serves as a common point for EC2 control
class EC2Runner < MiniTest::Unit
  include Loggable

  def initialize
    super
    puts <<-TXT.gsub(/^      /, '') unless skip_destroy?
      ==> WARNING: All EC2 instances tagged with
      ==>          knife_solo_integration_user == #{user}
      ==>          will be destroyed after the tests complete.
      ==> Please cancel (Control-c) NOW and re-run with SKIP_DESTROY=true
      ==> if you want to leave EC2 instances running.
    TXT
  end

  def skip_destroy?
    ENV['SKIP_DESTROY']
  end

  def user
    ENV['USER']
  end

  # Gets a server for the given tests
  # See http://bit.ly/MJRpfQ for information on what filters can be specified.
  def get_server(test)
    server = compute.servers.all("tag-key"             => "name",
                                 "tag-value"           => test.server_name,
                                 "instance-state-name" => "running").first
    if server
      logger.info "Reusing active server tagged #{test.server_name}"
    else
      logger.info "Starting server for #{test.class}..."
      server = compute.servers.create(:tags => {
                                        :name => test.server_name,
                                        :knife_solo_integration_user => ENV['USER']
                                      },
                                      :image_id => test.image_id,
                                      :flavor_id => test.flavor_id,
                                      :key_name => key_name)
    end
    server.wait_for { ready? }
    logger.info "Server reported ready, trying to connect to ssh..."
    server.wait_for do
      `nc #{public_ip_address} 22 -w 1 -q 0 </dev/null`
      $?.success?
    end
    logger.info "Sleeping 10s to avoid Net::SSH locking up by connecting too early..."
    logger.info "  (if you know a better way, please send me a note at https://github.com/matschaffer/knife-solo)"
    # These may have better ways:
    # http://rubydoc.info/gems/fog/Fog/Compute/AWS/Server:setup
    # http://rubydoc.info/gems/knife-ec2/Chef/Knife/Ec2ServerCreate:tcp_test_ssh
    sleep 10
    server
  end

  # Cleans up all the servers tagged as knife solo servers for this user.
  # Specify SKIP_DESTROY environment variable to skip this step and leave servers
  # running for inspection or reuse.
  def run_ec2_cleanup
    servers = compute.servers.all("tag-key"             => "knife_solo_integration_user",
                                  "tag-value"           => user,
                                  "instance-state-name" => "running").first
    if skip_destroy?
      puts "\nSKIP_DESTROY specified, leaving #{servers.size} instances running"
    else
      servers.each do |server|
        logger.info "Destroying #{server.public_ip_address}..."
        server.destroy
      end
    end
  end

  # Attempts to create the keypair used for integration testing
  # unless the key file is already present locally.
  def create_key_pair
    return if key_file.exist?
    begin
      key = compute.key_pairs.create(:name => key_name)
      key.write(key_file)
    rescue Fog::Compute::AWS::Error => e
      raise "Unable to create KeyPair 'knife-solo', please create the keypair and save it to #{key_file}"
    end
  end

  def key_name
    config['aws']['key_name']
  end

  def key_file
    $base_dir.join('support', "#{key_name}.pem")
  end

  def config_file
    $base_dir.join('support', 'config.yml')
  end

  def config
    @config ||= YAML.load_file(config_file)
  end

  # Provides a Fog compute resource associated with the
  # AWS account credentials provided in test/support/config.yml
  def compute
    @compute ||= Fog::Compute.new({:provider              => 'AWS',
                                   :aws_access_key_id     => config['aws']['access_key'],
                                   :aws_secret_access_key => config['aws']['secret']})
  end
end

MiniTest::Unit.runner = EC2Runner.new
MiniTest::Unit.runner.create_key_pair
