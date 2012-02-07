require 'test_helper'

MiniTest::Parallel.processor_count = [Dir['test/integration/*_test.rb'].size, 5].min

class IntegrationTest < TestCase
  def self.servers
    @servers ||= []
  end

  def self.cleanup_servers
    return if ENV['SKIP_DESTROY']
    puts "Cleaning up #{servers.length} servers..."
    servers.each do |server|
      puts "Destroying #{server} (#{server.public_ip_address})..."
      server.destroy
    end
  end

  def key_name
    'knife-solo'
  end

  def key_file
    "#{ENV['HOME']}/.ssh/#{key_name}.pem"
  end

  def flavor_id
    'm1.small'
  end

  def compute
    @compute ||= Fog::Compute.new({:provider              => 'AWS',
                                   :aws_access_key_id     => ENV['AWS_ACCESS_KEY'],
                                   :aws_secret_access_key => ENV['AWS_SECRET_KEY']})
  end

  def server
    return @server if @server
    puts "Starting server for #{self.class}..."
    @server = compute.servers.create(:image_id  => image_id,
                                     :flavor_id => flavor_id,
                                     :key_name  => key_name)
    IntegrationTest.servers << @server
    @server.wait_for { ready? }
    puts "Server reported ready, trying to connect to ssh..."
    @server.wait_for do
      `nc #{public_ip_address} 22 -w 1 -q 0 </dev/null`
      $?.success?
    end
    puts "Sleeping 10s to avoid Net::SSH locking up by connecting too early..."
    puts "  (if you know a better way, please send me a note at https://github.com/matschaffer/knife-solo)"
    sleep 10
    @server
  end

  module BasicPrepareAndCook
    def setup
      @kitchen = Pathname.new(__FILE__).dirname.join('kitchens', self.class.to_s)
      system "knife kitchen #{@kitchen}"
    end

    def teardown
      FileUtils.remove_entry_secure(@kitchen)
    end

    def run_subcommand(subcommand)
      verbose = ENV['VERBOSE'] && "-VV"
      system "knife #{subcommand} -i #{key_file} #{user}@#{server.public_ip_address} #{verbose}"
    end

    def test_prepare_and_cook
      Dir.chdir(@kitchen) do
        run_subcommand("prepare")
        assert $?.success?
        run_subcommand("cook")
        assert $?.success?
      end
    end
  end
end

MiniTest::Unit.after_tests { IntegrationTest.cleanup_servers }
