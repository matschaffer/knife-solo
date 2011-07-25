# Taken from Vagrant's patch: https://gist.github.com/867960
# based on Brian Akins's patch: http://lists.opscode.com/sympa/arc/chef/2011-02/msg00000.html
if Chef::Config[:solo]
  class Chef
    module Mixin
      module Language
        def data_bag(bag)
          @solo_data_bags = {} if @solo_data_bags.nil?
          unless @solo_data_bags[bag]
            @solo_data_bags[bag] = {}
            data_bag_path = Chef::Config[:data_bag_path]
            Dir.glob(File.join(data_bag_path, bag, "*.json")).each do |f|
              item = JSON.parse(IO.read(f))
              @solo_data_bags[bag][item['id']] = item
            end
          end
          @solo_data_bags[bag].keys
        end

        def data_bag_item(bag, item)
          data_bag(bag) unless ( !@solo_data_bags.nil? && @solo_data_bags[bag])
          @solo_data_bags[bag][item]
        end

      end
    end
  end

  class Chef
    class Recipe
      def search(bag_name, query=nil)
        Chef::Log.warn("Simplistic search patch, ignoring query of %s" % [query]) unless query.nil?
        data_bag(bag_name.to_s).each do |bag_item_id|
          bag_item = data_bag_item(bag_name.to_s, bag_item_id)
          yield bag_item
        end
      end

    end
  end

end
