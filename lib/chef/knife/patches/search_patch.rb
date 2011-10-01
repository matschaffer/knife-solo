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
    class Recipe
      
      # Overwrite the search method of recipes to operate locally by using
      # data found in data_bags.
      # Only very basic lucene syntax is supported and also sorting the result
      # is not implemented, if this search method does not support a given query
      # an exception is raised.
      # This search() method returns a block iterator or an Array, depending
      # on how this method is called.
      def search(bag_name, query=nil, sort=nil, start=0, rows=1000, &block)
        if !sort.nil?
          raise "Sorting search results is not supported"
        end
        @_query = Query.parse(query)
        if @_query.nil?
          raise "Query #{query} is not supported"
        end
        if block_given?
          pos = 0
        else
          result = []
        end
        data_bag(bag_name.to_s).each do |bag_item_id|
          bag_item = data_bag_item(bag_name.to_s, bag_item_id)
          if @_query.match(bag_item)
            if block_given?
              if (pos >= start and pos < (start + rows))
                yield bag_item
              end
              pos += 1
            else
              result << bag_item
            end
          end
        end
        if !block_given?
          return result.slice(start, rows)
        end
      end
    end
  end

end
