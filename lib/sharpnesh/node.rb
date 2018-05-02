module Sharpnesh
  # Return value of parser
  class Node
    attr_reader :type

    def initialize(type, **children)
      @type = type

      singleton_class.class_eval do
        attr_reader(*children.keys)
      end

      children.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end
  end
end
