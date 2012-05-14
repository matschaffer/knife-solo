require 'test_helper'
require 'pathname'
require 'logger'
require 'yaml'
require 'net/http'

MiniTest::Parallel.processor_count = 5

$stderr.puts <<-TXT
==> NOTE: Integration tests run in parallel.
          Please make sure to clean up EC2 instances if you interrupt (Ctrl-c) the test.
TXT

class IntegrationTest < TestCase
  class Helper
    def base_dir
      Pathname.new(__FILE__).dirname
    end

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
      base_dir.join('support', "#{key_name}.pem")
    end

    def config_file
      base_dir.join('support', 'config.yml')
    end

    def config
      @config ||= YAML.load_file(config_file)
    end

    def compute
      @compute ||= Fog::Compute.new({:provider              => 'AWS',
                                     :aws_access_key_id     => config['aws']['access_key'],
                                     :aws_secret_access_key => config['aws']['secret']})
    end
  end

  def helper
    @helper ||= Helper.new
  end

  def base_dir; helper.base_dir; end
  def key_name; helper.key_name; end
  def key_file; helper.key_file; end
  def compute; helper.compute; end

  def server
    return @server if @server
    logger.info "Starting server for #{self.class}..."
    @server = compute.servers.create(:image_id => image_id,
                                     :flavor_id => flavor_id,
                                     :key_name => key_name)
    @server.wait_for { ready? }
    logger.info "Server reported ready, trying to connect to ssh..."
    @server.wait_for do
      `nc #{public_ip_address} 22 -w 1 -q 0 </dev/null`
      $?.success?
    end
    logger.info "Sleeping 10s to avoid Net::SSH locking up by connecting too early..."
    logger.info "  (if you know a better way, please send me a note at https://github.com/matschaffer/knife-solo)"
    sleep 10
    @server
  end

  def cleanup_server
    return if ENV['SKIP_DESTROY']
    logger.info "Destroying #{self.class} (#{server.public_ip_address})..."
    server.destroy
  end

  def flavor_id
    "m1.small"
  end

  def log_file
    return @log_file if @log_file
    @log_file = base_dir.join('..', 'log', "#{self.class}-integration.log")
    @log_file.dirname.mkpath
    @log_file
  end

  def logger
    @logger ||= Logger.new(log_file)
  end

  def teardown
    cleanup_server
  end

  module BasicPrepareAndCook
    def setup
      @kitchen = base_dir.join('support', 'kitchens', self.class.to_s)
      @kitchen.dirname.mkpath
      system "knife kitchen #{@kitchen} >> #{log_file}"
    end

    def teardown
      FileUtils.remove_entry_secure(@kitchen)
      super
    end

    def assert_subcommand(subcommand)
      verbose = ENV['VERBOSE'] && "-VV"
      system "knife #{subcommand} -i #{key_file} #{user}@#{server.public_ip_address} #{verbose} >> #{log_file}"
      assert $?.success?
    end

    def test_prepare_and_cook
      Dir.chdir(@kitchen) do
        assert_subcommand "prepare"
        assert_subcommand "cook"
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

IntegrationTest::Helper.new.create_key_pair
