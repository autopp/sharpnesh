module Sharpnesh
  # Return value of parser
  class Node
    attr_reader :type, :children

    def initialize(type, **children)
      @type = type
      @children = children

      singleton_class.class_eval do
        attr_reader(*children.keys)
      end

      children.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def ==(other)
      other.is_a?(Node) && type == other.type && children == other.children
    end

    def inspect
      str = "(#{type}"
      @children.each do |k, v|
        str << " (#{k} #{v.inspect})"
      end
      str << ')'
    end
  end
end
