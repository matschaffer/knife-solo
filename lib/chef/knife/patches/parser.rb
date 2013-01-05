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

require 'treetop'
require 'chef/solr_query/query_transform'

# mock QueryTransform such that we can access the location of the lucene grammar
class Chef
  class SolrQuery
    class QueryTransform
      def self.base_path
        class_variable_get(:@@base_path)
      end
    end
  end
end

def build_flat_hash(hsh, prefix="")
  result = {}
  hsh.each_pair do |key, value|
    if value.kind_of?(Hash)
      result.merge!(build_flat_hash(value, "#{prefix}#{key}_"))
    else
      result[prefix+key] = value
    end
  end
  result
end

module Lucene

  class Term < Treetop::Runtime::SyntaxNode
    # compares a query value and a value, tailing '*'-wildcards are handled correctly.
    # Value can either be a string or an array, all other objects are converted
    # to a string and than checked.
    def match( value )
      if value.is_a?(Array)
        value.any?{ |x| self.match(x) }
      else
        File.fnmatch(self.text_value, value.to_s)
      end
    end
  end

  class Field < Treetop::Runtime::SyntaxNode
    # simple field -> value matches, supporting tailing '*'-wildcards in keys
    # as well as in values
    def match( item )
      keys = self.elements[0].match(item)
      if keys.nil?
        false
      else
        keys.any?{ |key| self.elements[1].match(item[key]) }
      end
    end
  end

  # we don't support range matches
  # range of integers would be easy to implement
  # but string ranges are hard
  class FiledRange < Treetop::Runtime::SyntaxNode
  end

  # we handle '[* TO *]' as a special case since it is common in
  # cookbooks for matching the existence of keys
  class InclFieldRange
    def match(item)
      field = self.elements[0].text_value
      range_start = self.elements[1].transform
      range_end = self.elements[2].transform
      if range_start == "*" and range_end == "*"
        !!item[field]
      else
        raise "Ranges not really supported yet"
      end
    end
  end

  class ExclFieldRange < FieldRange
  end

  class RangeValue < Treetop::Runtime::SyntaxNode
  end

  class FieldName < Treetop::Runtime::SyntaxNode
    def match( item )
      if self.text_value.count("_") > 0
        item.merge!(build_flat_hash(item))
      end
      if self.text_value.end_with?("*")
        part = self.text_value.chomp("*")
        item.keys.collect{ |key| key.start_with?(part)? key: nil}.compact
      else
        if item[self.text_value]
          [self.text_value,]
        else
          nil
        end
      end
    end
  end

  class Body < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[0].match( item )
    end
  end

  class Group < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[0].match(item)
    end
  end

  class BinaryOp < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[1].match(
        self.elements[0].match(item),
        self.elements[2].match(item)
      )
    end
  end

  class OrOperator < Treetop::Runtime::SyntaxNode
    def match( cond1, cond2 )
      cond1 or cond2
    end
  end

  class AndOperator < Treetop::Runtime::SyntaxNode
    def match( cond1, cond2 )
      cond1 and cond2
    end
  end

  # we don't support fuzzy string matching
  class FuzzyOp < Treetop::Runtime::SyntaxNode
  end

  class BoostOp < Treetop::Runtime::SyntaxNode
  end

  class FuzzyParam < Treetop::Runtime::SyntaxNode
  end

  class UnaryOp < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[0].match(
        self.elements[1].match(item)
      )
    end
  end

  class NotOperator < Treetop::Runtime::SyntaxNode
    def match( cond )
      not cond
    end
  end

  class RequiredOperator < Treetop::Runtime::SyntaxNode
  end

  class ProhibitedOperator < Treetop::Runtime::SyntaxNode
  end

  class Phrase < Treetop::Runtime::SyntaxNode
    # a quoted ::Term
    def match( value )
      self.elements[0].match(value)
    end
  end
end

class Query
  # initialize the parser by using the grammar shipped with chef
  @@grammar = File.join(Chef::SolrQuery::QueryTransform.base_path, "lucene.treetop")
  Treetop.load(@@grammar)
  @@parser = LuceneParser.new

  def self.parse(data)
    # parse the query into a query tree
    if data.nil?
      data = "*:*"
    end
    tree = @@parser.parse(data)
    if tree.nil?
      msg = "Parse error at offset: #{@@parser.index}\n"
      msg += "Reason: #{@@parser.failure_reason}"
      raise "Query #{data} is not supported: #{msg}"
    end
    self.clean_tree(tree)
    tree
  end

  private

  def self.clean_tree(root_node)
    # remove all SyntaxNode elements from the tree, we don't need them as
    # the related ruby class already knowns what to do.
    return if root_node.elements.nil?
    root_node.elements.delete_if do |node|
      node.class.name == "Treetop::Runtime::SyntaxNode"
    end
    root_node.elements.each { |node| self.clean_tree(node) }
  end
end

