require 'virtualbox'

class VirtualBox::VM
  def find_first_interface(type)
    network_adapters.detect { |a| a.attachment_type == type }
  end

  def find_usable_interface
    host_only = find_first_interface(:host_only)
    return host_only.slot if host_only

    bridged = find_first_interface(:bridged)
    return bridged.slot if bridged

    raise "VM does not have any Host-only or bridged interfaces"
  end

  def get_ip_address
    slot = find_usable_interface
    interface.get_guest_property_value("/VirtualBox/GuestInfo/Net/#{slot}/V4/IP")
  end

  def ip_address
    sleep 1 while get_ip_address.empty?
    get_ip_address
  end
end

module VirtualBox
  extend Rake::DSL

  def self.define_rake_tasks(options)
    run_mode = options[:run_mode] || :gui
    image = options[:image]
    hosts = options[:hosts]

    namespace :virtualbox do
      desc 'Imports virtualbox images for each host'
      task :import do
        hosts.each do |type, host|
          next if host[:vm] = VirtualBox::VM.find(host[:name])
          host[:vm] = VirtualBox::VM.import(image) do |progress|
            print "Importing #{host[:name]}: #{progress.percent}%\r"
          end
          puts "Importing #{host[:name]}: 100%"
          host[:vm].name = host[:name]
          host[:vm].network_adapters.each { |a| a.mac_address = nil }
          host[:vm].save
        end
      end

      desc 'Starts the virtualbox hosts'
      task :start => :import do
        hosts.each do |type, host|
          host[:vm].start(run_mode)
        end
      end

      desc 'Show IP addresses for the virtualbox hosts'
      task :info => :start do
        hosts.each do |type, host|
          puts "#{type.capitalize}: #{host[:vm].ip_address}"
        end
      end

      desc 'Stops the virtualbox hosts'
      task :stop do
        hosts.each do |type, host|
          host[:vm] = VirtualBox::VM.find(host[:name])
          host[:vm].shutdown if host[:vm].running?
        end
      end

      desc 'Destroys the virtualbox hosts'
      task :destroy => :stop do
        hosts.each do |type, host|
          while host[:vm].running?
            sleep 1
            host[:vm].reload
          end
          sleep 1 # One more sleep incase it's not _really_ stopped
          host[:vm].destroy(:destroy_medium => true)
        end
      end
    end
  end
end
