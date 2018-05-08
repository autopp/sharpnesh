module Sharpnesh
  # Parser provides features of parsing a bash script
  #
  class Parser
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

    class ParseError < StandardError
    end
  end
end

require 'sharpnesh/parser/lexer'
