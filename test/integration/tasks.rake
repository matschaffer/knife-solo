KEY_FILE = "#{ENV['HOME']}/.ssh/knife-solo.pem"

def prepare(user, server)
  system "knife prepare -i #{KEY_FILE} #{user}@#{server.public_ip_address}"
end

def cook(user, server)
  system "knife cook -i #{KEY_FILE} #{user}@#{server.public_ip_address}"
end

namespace :test do
  KITCHEN = "test/integration/kitchen"
  AMIS = {
    'Ubuntu 10.04' => { :user => 'ubuntu',
                        :image_id => 'ami-6936fb00' }
  }

  desc "Create a test kitchen"
  file KITCHEN do
    system "knife kitchen #{KITCHEN}"
  end

  desc "Run integration tests (requires EC2)"
  task :integration => 'test/integration/kitchen' do
    require 'bundler'
    Bundler.require(:test)
    require 'socket'

    File.new(KEY_FILE).chmod(0600)

    compute = Fog::Compute.new({:provider => 'AWS',
                                :aws_access_key_id => ENV['AWS_ACCESS_KEY'],
                                :aws_secret_access_key => ENV['AWS_SECRET_KEY'],
                               })
    servers = []
    begin
      AMIS.each do |type, info|
        puts "Starting test run for #{type}..."
        server = compute.servers.create(:image_id => info[:image_id],
                                        :flavor_id => 'm1.small',
                                        :key_name => "knife-solo")
        servers << server
        server.wait_for { ready? }
        puts "Server reported ready, trying to connect to ssh..."
        server.wait_for {
          `nc #{server.public_ip_address} 22 -w 1 -q 0 </dev/null`
          $?.success?
        }
        Dir.chdir KITCHEN do
          prepare(info[:user], server)
          cook(info[:user], server)
        end
      end
    ensure
      servers.map do |server|
        puts "Destroying #{server}"
        server.destroy
      end
    end

  end
end