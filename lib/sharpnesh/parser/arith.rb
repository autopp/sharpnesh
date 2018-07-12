module Sharpnesh
  class Parser
    # Arith provides methods for parsing arithmetic expression
    #
    module Arith
      include Sharpnesh::Parser::TokenType

      ARITH_RULES = [
        { pattern: /\d+/, method: :on_token, opt: TK_NUMBER },
        { pattern: /[a-zA-Z_][a-zA-Z_0-9]*/, method: :on_token, opt: TK_VAR }
      ].freeze

      def parse_arith(lexer)
        lexer.use_rules(ARITH_RULES, allow_blank: true) do
          parse_primary_expr(lexer)
        end
      end

      def parse_primary_expr(lexer)
        if (number = lexer.next(TK_NUMBER))
          Node.new(:number, value: number.body)
        elsif (var = lexer.next(TK_VAR))
          Node.new(:var, name: var.body)
        else
          raise ParseError, 'expect primary expression'
        end
      end
    end
  end
end
