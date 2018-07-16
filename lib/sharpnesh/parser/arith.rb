module Sharpnesh
  class Parser
    # Arith provides methods for parsing arithmetic expression
    #
    module Arith
      include Sharpnesh::Parser::TokenType

      ARITH_RULES = [
        { pattern: /\d+/, method: :on_token, opt: TK_NUMBER },
        { pattern: /\$?[a-zA-Z_][a-zA-Z_0-9]*/, method: :on_token, opt: TK_VAR },
        { pattern: /,/, method: :on_token, opt: TK_COMMA },
        { pattern: %r{([-+*/%^&|]|<<|>>)?\=}, method: :on_token, opt: TK_ASSIGN },
        { pattern: /[?]/, method: :on_token, opt: TK_QUESTION },
        { pattern: /:/, method: :on_token, opt: TK_COLON },
        { pattern: /[|]{2}/, method: :on_token, opt: TK_LOR }
      ].freeze

      def parse_arith(lexer)
        lexer.use_rules(ARITH_RULES, allow_blank: true) do
          parse_comma_expr(lexer)
        end
      end

      def parse_comma_expr(lexer)
        expr = parse_assign_expr(lexer)
        expr = Node.new(:binop, op: ',', left: expr, right: parse_assign_expr(lexer)) while lexer.next(TK_COMMA)
        expr
      end

      def parse_assign_expr(lexer)
        if (left = lexer.next(TK_VAR))
          if (op = lexer.next(TK_ASSIGN))
            Node.new(:binop, op: op.body, left: Node.new(:var, name: left.body), right: parse_assign_expr(lexer))
          else
            lexer.back
            parse_ternary_op_expr(lexer)
          end
        else
          parse_ternary_op_expr(lexer)
        end
      end

      def parse_ternary_op_expr(lexer)
        cond = parse_lor_expr(lexer)
        return cond if !lexer.next(TK_QUESTION)
        then_expr = parse_comma_expr(lexer)
        raise ParseError, 'expected `:`' if !lexer.next(TK_COLON)
        Node.new(:terop, cond: cond, then: then_expr, else: parse_ternary_op_expr(lexer))
      end

      def parse_lor_expr(lexer)
        expr = parse_primary_expr(lexer)
        expr = Node.new(:binop, op: '||', left: expr, right: parse_lor_expr(lexer)) while lexer.next(TK_LOR)
        expr
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
