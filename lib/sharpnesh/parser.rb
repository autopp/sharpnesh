module Sharpnesh
  # Parser provides features of parsing a bash script
  #
  class Parser
    TK_ASSIGN = :'='
    TK_LPAREN = :'('
    TK_RPAREN = :')'
    TK_LPAREN2 = :'(('
    TK_RPAREN2 = :'))'
    TK_LBRACKET2 = :'[['
    TK_RBRACKET2 = :']]'
    TK_FOR = :for
    TK_IN = :in
    TK_SEMICOLON = :';'
    TK_DO = :do
    TK_DONE = :done
    TK_SELECT = :select
    TK_CASE = :case
    TK_SEMICOLON2 = :';;'
    TK_ESAC = :esac
    TK_IF = :if
    TK_THEN = :then
    TK_ELIF = :elif
    TK_ELSE = :else
    TK_FI = :fi
    TK_WHILE = :while
    TK_UNTIL = :until
    TK_TIME = :time
    TK_OPT_P = :'-p'
    TK_NOT = :'!'
    TK_PIPE = :'|'
    TK_PIPE_AND = :'|&'
    TK_LAND = :'&&'
    TK_LOR = :'||'
    TK_AND = :&
    TK_NEWLINE = :'\n'
    TK_COMMA = :','
    TK_MUL_ASSIGN = :'*='
    TK_DIV_ASSIGN = :'/='
    TK_MOD_ASSIGN = :'%='
    TK_ADD_ASSIGN = :'+='
    TK_SUB_ASSIGN = :'-='
    TK_LSHIFT_ASSIGN = :'<<='
    TK_RSHIFT_ASSIGN = :'>>='
    TK_BAND_ASSIGN = :'&='
    TK_BXOR_ASSIGN = :'^='
    TK_BOR_ASSIGN = :'|='
    TK_QUESTION = :'?'
    TK_COLON = :':'
    TK_BOR = TK_PIPE
    TK_BXOR = :'^'
    TK_BAND = TK_AND
    TK_EQL = :==
    TK_NEQ = :'!='
    TK_LEQ = :<=
    TK_REQ = :>=
    TK_LTN = :<
    TK_RTN = :>
    TK_LSHIFT = :<<
    TK_RSHIFT = :>>
    TK_ADD = :+
    TK_SUB = :-
    TK_MUL = :*
    TK_DIV = :/
    TK_MOD = :%
    TK_EXP = :**
    TK_BNOT = :~
    TK_INC = :'++'
    TK_DEC = :'--'

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
