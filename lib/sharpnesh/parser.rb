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

    def parse_pipeline(lexer)
      not_op = lexer.next(TK_NOT)
      command = parse_command(lexer)
      while (pipe = lexer.next(TK_PIPE, TK_PIPE_AND))
        pipeline = Node.new(:pipe, pipe: pipe, lhs: command, rhs: parse_command(lexer))
      end
      Node.new(:pipeline, excl: not_op, command: pipeline)
    end

    def parse_command(lexer)
      parse_simple_command(lexer)
    end

    def parse_simple_command(lexer)
      parse_word(lexer)
    end

    def parse_word(lexer)
      lexer.next(TK_NAME) || raise(ParseError, "unexpected token: #{lexer.peek}")
    end

    class ParseError < StandardError
    end
  end
end

require 'sharpnesh/parser/lexer'
