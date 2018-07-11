module Sharpnesh
  class Parser
    # Arith provides methods for parsing arithmetic expression
    #
    module Arith
      include Sharpnesh::Parser::TokenType

      ARITH_RULES = [
        { pattern: /\d+/, method: :on_token, opt: TK_NUMBER }
      ].freeze

      def parse_arith(lexer)
        lexer.use_rules(ARITH_RULES, allow_blank: true) do
          # TODO: parsing full syntax
          raise ParseError, 'expect number' if !(token = lexer.next(TK_NUMBER))
          Node.new(:number, value: token.body)
        end
      end
    end
  end
end
