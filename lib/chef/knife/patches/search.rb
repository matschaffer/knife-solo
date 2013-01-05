#
# Copyright 2011, edelight GmbH
#
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if Chef::Config[:solo]

  if (defined? require_relative).nil?
    # defenition of 'require_relative' for ruby < 1.9, found on stackoverflow.com
    def require_relative(relative_feature)
      c = caller.first
      fail "Can't parse #{c}" unless c.rindex(/:\d+(:in `.*')?$/)
      file = $`
      if /\A\((.*)\)/ =~ file # eval, etc.
        raise LoadError, "require_relative is called in #{$1}"
      end
      absolute = File.expand_path(relative_feature, File.dirname(file))
      require absolute
    end
  end

  require_relative 'parser.rb'

  class Chef
    module Mixin
      module Language

        # Overwrite the search method of recipes to operate locally by using
        # data found in data_bags.
        # Only very basic lucene syntax is supported and also sorting the result
        # is not implemented, if this search method does not support a given query
        # an exception is raised.
        # This search() method returns a block iterator or an Array, depending
        # on how this method is called.
        def search(obj, query=nil, sort=nil, start=0, rows=1000, &block)
          if !sort.nil?
            raise "Sorting search results is not supported"
          end
          @_query = Query.parse(query)
          if @_query.nil?
            raise "Query #{query} is not supported"
          end
          @_result = []

          case obj
          when :node
            search_nodes(start, rows, &block)
          when :role
            search_roles(start, rows, &block)
          else
            search_data_bag(obj, start, rows, &block)
          end


          if block_given?
            pos = 0
            while (pos >= start and pos < (start + rows) and pos < @_result.size)
              yield @_result[pos]
              pos += 1
            end
          else
            return @_result.slice(start, rows)
          end
        end

        def search_nodes(start, rows, &block)
          Dir.glob(File.join(Chef::Config[:data_bag_path], "node", "*.json")).map do |f|
            # parse and hashify the node
            node = JSON.parse(IO.read(f))
            if @_query.match(node.to_hash)
              @_result << node
            end
          end
        end

        def search_roles(start, rows, &block)
          raise "Role searching not implemented"
        end

        def search_data_bag(bag_name, start, rows, &block)
          secret_path = Chef::Config[:encrypted_data_bag_secret]
          data_bag(bag_name.to_s).each do |bag_item_id|
            if secret_path && secret = Chef::EncryptedDataBagItem.load_secret(secret_path)
              bag_item = Chef::EncryptedDataBagItem.load(bag_name, bag_item_id, secret)
            else
              bag_item = data_bag_item(bag_name.to_s, bag_item_id)
            end
            if @_query.match(bag_item)
              @_result << bag_item
            end
          end
        end
      end
    end
  end
end
