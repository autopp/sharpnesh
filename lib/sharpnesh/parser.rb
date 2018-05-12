module Sharpnesh
  # Parser provides features of parsing a bash script
  #
  class Parser
    require 'sharpnesh/parser/token_type'
    include TokenType

    def parse(io, name)
      lexer = Lexer.new(io, name)
      parse_list(lexer)
    end

    def parse_list(lexer)
      pipelines = parse_pipelines(lexer)
      terminal = lexer.next
      unless %i[newline eos semicolon &].include?(terminal.type)
        raise ParseError, "unexpected token #{terminal.body}"
      end
      Node.new(:list, body: pipelines, terminal: terminal.body)
    end

    def parse_pipelines(lexer)
      pipelines = parse_pipeline(lexer)
      while (op = lexer.next(TK_LAND, TL_LOR))
        pipelines = Node.new(:pipelines, op: op, lhs: pipelines, rhs: parse_pipeline(lexer))
      end
      pipelines
    end

    class ParseError < StandardError
    end
  end
end

require 'sharpnesh/parser/lexer'
