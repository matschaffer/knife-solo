require 'test_helper'
require 'support/kitchen_helper'
require 'chef/knife/solo_prepare'

require 'knife-solo/bootstraps'
require 'knife-solo/bootstraps/linux'

require 'knife-solo/ssh_connection'

require 'benchmark'

class KnifeSolo::Bootstraps::Linux
  def debianoid_omnibus_install
    run_command("echo apt-get update")
    run_command("echo apt-get install")
    run_command("echo curl omnibus")
    run_command("echo run omnibus")
  end
end

class SshPerformanceTest < TestCase
  include KitchenHelper

  def do_it
    # NOTE: Assumes user & host on @matschaffer's machine. Modify or paramaterize if needed.
    10.times { knife_command(Chef::Knife::SoloPrepare, "ubuntu@172.16.20.133").run }
  end

  def test_ssh_performance_of_prepare
    in_kitchen do
      Benchmark.bmbm do |b|
        b.report("cached attributes: ") do
          do_it
        end
      end
    end
  end
end
